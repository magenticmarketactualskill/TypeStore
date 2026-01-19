# frozen_string_literal: true

class WebhookSubscription < ApplicationRecord
  EVENTS = %w[
    version.published
    schema.deprecated
    schema.deleted
    schema.updated
  ].freeze

  # Associations
  belongs_to :user

  # Validations
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :events, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :for_event, ->(event) { where('? = ANY(events)', event) }
  scope :for_schema, ->(ref) { where('? = ANY(schema_refs)', ref) }

  # Find subscriptions matching a schema and event
  def self.matching(schema_ref:, event:)
    active
      .for_event(event)
      .where('schema_refs = \'{}\' OR ? = ANY(schema_refs)', schema_ref)
  end

  # Check if subscription watches an event
  def watches_event?(event)
    events.include?(event)
  end

  # Check if subscription watches a schema
  def watches_schema?(ref)
    schema_refs.empty? || schema_refs.include?(ref)
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
