# frozen_string_literal: true

class ApiSpecVersion < ApplicationRecord
  include SemanticVersioning

  # Associations
  belongs_to :api_spec
  belongs_to :published_by, class_name: 'User', optional: true

  # Validations
  validates :version, presence: true, uniqueness: { scope: :api_spec_id }
  validates :version_major, :version_minor, :version_patch, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :content, presence: true
  validates :content_hash, presence: true

  # Callbacks
  before_validation :parse_version, if: -> { version.present? && version_major.nil? }
  before_validation :compute_content_hash, if: -> { content.present? && content_hash.blank? }

  # Scopes
  scope :published, -> { where.not(published_at: nil) }
  scope :draft, -> { where(published_at: nil) }
  scope :ordered, -> { order(version_major: :desc, version_minor: :desc, version_patch: :desc) }

  # Delegate namespace and spec_type access
  delegate :namespace, :spec_type, to: :api_spec

  # Returns the full reference string
  def ref
    "#{api_spec.ref}@#{version}"
  end

  # Check if published
  def published?
    published_at.present?
  end

  # Publish the version
  def publish!(user)
    update!(published_at: Time.current, published_by: user)
    api_spec.update!(current_version: self)
  end

  # Get raw content (for YAML-based formats)
  def raw
    raw_content.presence || content.to_json
  end

  private

  def compute_content_hash
    self.content_hash = Digest::SHA256.hexdigest(content.to_json)
  end
end
