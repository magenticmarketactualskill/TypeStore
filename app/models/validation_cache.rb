# frozen_string_literal: true

class ValidationCache < ApplicationRecord
  # Scopes
  scope :valid, -> { where(is_valid: true) }
  scope :invalid, -> { where(is_valid: false) }
  scope :recent, -> { where('created_at > ?', 1.hour.ago) }
  scope :stale, -> { where('created_at <= ?', 1.hour.ago) }

  # Find cached validation result
  def self.find_cached(schema_type:, schema_id:, schema_version_id:, data_hash:)
    where(
      schema_type: schema_type,
      schema_id: schema_id,
      schema_version_id: schema_version_id,
      data_hash: data_hash
    ).recent.first
  end

  # Cache a validation result
  def self.cache_result(schema_type:, schema_id:, schema_version_id:, data:, is_valid:, errors: nil)
    data_hash = compute_data_hash(data)

    create!(
      schema_type: schema_type,
      schema_id: schema_id,
      schema_version_id: schema_version_id,
      data_hash: data_hash,
      is_valid: is_valid,
      errors: errors
    )
  end

  # Compute hash for data
  def self.compute_data_hash(data)
    Digest::SHA256.hexdigest(data.to_json)
  end

  # Clean up stale cache entries
  def self.cleanup_stale!
    stale.delete_all
  end

  # Invalidate cache for a schema version
  def self.invalidate_for_version!(schema_type:, schema_id:, schema_version_id:)
    where(
      schema_type: schema_type,
      schema_id: schema_id,
      schema_version_id: schema_version_id
    ).delete_all
  end
end
