# frozen_string_literal: true

class WebhookSubscription < ApplicationRecord
  EVENTS = %w[
    version.published
    schema.deprecated
    schema.deleted
    schema.updated
  ].freeze

  # Serialize arrays as JSON for SQLite compatibility
  serialize :events, coder: JSON
  serialize :schema_refs, coder: JSON

  # Associations
  belongs_to :user

  # Validations
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :events, presence: true

  # Callbacks
  before_validation :initialize_arrays

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Find subscriptions for a specific event (SQLite compatible)
  def self.for_event(event)
    where("events LIKE ?", "%#{event}%")
  end

  # Find subscriptions for a specific schema (SQLite compatible)
  def self.for_schema(ref)
    where("schema_refs LIKE ?", "%#{ref}%")
  end

  # Find subscriptions matching a schema and event
  def self.matching(schema_ref:, event:)
    active.select do |sub|
      sub.watches_event?(event) && sub.watches_schema?(schema_ref)
    end
  end

  # Check if subscription watches an event
  def watches_event?(event)
    events_array.include?(event)
  end

  # Check if subscription watches a schema
  def watches_schema?(ref)
    refs = schema_refs_array
    refs.empty? || refs.include?(ref)
  end

  def events_array
    events.is_a?(Array) ? events : (events.present? ? JSON.parse(events) : [])
  rescue JSON::ParserError
    []
  end

  def schema_refs_array
    schema_refs.is_a?(Array) ? schema_refs : (schema_refs.present? ? JSON.parse(schema_refs) : [])
  rescue JSON::ParserError
    []
  end

  private

  def initialize_arrays
    self.events ||= []
    self.schema_refs ||= []
  end

  # Activate/deactivate
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  # Generate signature for payload
  def sign_payload(payload)
    return nil unless secret.present?

    OpenSSL::HMAC.hexdigest('SHA256', secret, payload.to_json)
  end

  # Regenerate secret
  def regenerate_secret!
    update!(secret: SecureRandom.hex(32))
  end
end
