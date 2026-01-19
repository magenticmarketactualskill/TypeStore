# frozen_string_literal: true

class AccessGrant < ApplicationRecord
  PERMISSIONS = %w[read write admin validate].freeze

  # Polymorphic associations
  belongs_to :grantable, polymorphic: true
  belongs_to :grantee, polymorphic: true

  # Validations
  validates :grantable_type, presence: true
  validates :grantee_type, presence: true, inclusion: { in: %w[User Organization] }
  validates :permission, presence: true, inclusion: { in: PERMISSIONS }

  # Scopes
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :for_user, ->(user) { where(grantee: user) }
  scope :for_organization, ->(org) { where(grantee: org) }
  scope :read_access, -> { where(permission: %w[read write admin]) }
  scope :write_access, -> { where(permission: %w[write admin]) }
  scope :admin_access, -> { where(permission: 'admin') }

  def active?
    expires_at.nil? || expires_at > Time.current
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def can_read?
    %w[read write admin].include?(permission)
  end

  def can_write?
    %w[write admin].include?(permission)
  end

  def can_admin?
    permission == 'admin'
  end

  def can_validate?
    %w[validate read write admin].include?(permission)
  end
end
