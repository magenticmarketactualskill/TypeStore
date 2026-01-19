# frozen_string_literal: true

class OrganizationMembership < ApplicationRecord
  # Associations
  belongs_to :organization
  belongs_to :user

  # Validations
  validates :role, presence: true, inclusion: { in: %w[owner admin member viewer] }
  validates :user_id, uniqueness: { scope: :organization_id }

  # Scopes
  scope :owners, -> { where(role: 'owner') }
  scope :admins, -> { where(role: %w[owner admin]) }
  scope :with_write_access, -> { where(role: %w[owner admin member]) }
end
