# frozen_string_literal: true

class Namespace < ApplicationRecord
  # Associations
  belongs_to :owner, polymorphic: true
  has_many :type_definitions, dependent: :destroy
  has_many :data_shapes, dependent: :destroy
  has_many :api_specs, dependent: :destroy
  has_many :access_grants, as: :grantable, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A@?[a-z0-9][a-z0-9\-]*[a-z0-9]\z/i,
                             message: 'must start with @ and contain only alphanumeric characters and hyphens' }
  validates :visibility, presence: true, inclusion: { in: %w[public private internal] }
  validates :owner_type, presence: true, inclusion: { in: %w[User Organization] }

  # Callbacks
  before_validation :normalize_slug, on: :create

  # Scopes
  scope :public_namespaces, -> { where(visibility: 'public') }
  scope :visible_to, ->(user) {
    return public_namespaces if user.nil?

    where(visibility: 'public')
      .or(where(owner: user))
      .or(where(owner_type: 'Organization', owner_id: user.organizations.select(:id)))
  }

  # Returns the display name with @ prefix
  def display_slug
    slug.start_with?('@') ? slug : "@#{slug}"
  end

  # Check if user has access
  def accessible_by?(user)
    return true if visibility == 'public'
    return false if user.nil?
    return true if owner == user
    return true if owner.is_a?(Organization) && owner.member?(user)

    access_grants.exists?(grantee: user)
  end

  # Check if user can write
  def writable_by?(user)
    return false if user.nil?
    return true if owner == user
    return true if owner.is_a?(Organization) && owner.admin?(user)

    access_grants.exists?(grantee: user, permission: %w[write admin])
  end

  private

  def normalize_slug
    return if slug.blank?

    self.slug = slug.downcase
    self.slug = "@#{slug}" unless slug.start_with?('@')
  end
end
