# frozen_string_literal: true

class AuditLog < ApplicationRecord
  # Associations
  belongs_to :auditable, polymorphic: true
  belongs_to :user, optional: true

  # Validations
  validates :action, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_user, ->(user) { where(user: user) }
  scope :in_period, ->(start_time, end_time) { where(created_at: start_time..end_time) }

  # Actions
  ACTIONS = %w[
    create update delete
    publish deprecate restore
    version_created version_published
    access_granted access_revoked
    tag_added tag_removed
  ].freeze

  # Create an audit log entry
  def self.record(auditable:, user:, action:, changes: nil, metadata: {}, request: nil)
    create!(
      auditable: auditable,
      user: user,
      action: action,
      changes_data: changes,
      metadata: metadata,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    )
  end

  # Human-readable description
  def description
    entity_name = auditable&.respond_to?(:name) ? auditable.name : auditable_type
    user_name = user&.name || 'System'

    "#{user_name} #{action.humanize.downcase} #{entity_name}"
  end
end
