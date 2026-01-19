# frozen_string_literal: true

class Organization < ApplicationRecord
  # Associations
  has_many :organization_memberships, dependent: :destroy
  has_many :members, through: :organization_memberships, source: :user
  has_many :namespaces, as: :owner, dependent: :restrict_with_error
  has_many :access_grants, as: :grantee, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9][a-z0-9\-]*[a-z0-9]\z/i,
                             message: 'must start and end with alphanumeric characters' }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Membership helpers
  def add_member(user, role: 'member')
    organization_memberships.create!(user: user, role: role)
  end

  def remove_member(user)
    organization_memberships.find_by(user: user)&.destroy
  end

  def member?(user)
    organization_memberships.exists?(user: user)
  end

  def owner?(user)
    organization_memberships.exists?(user: user, role: 'owner')
  end

  def admin?(user)
    organization_memberships.exists?(user: user, role: %w[owner admin])
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = name.to_s.parameterize
    self.slug = base_slug

    counter = 1
    while Organization.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
