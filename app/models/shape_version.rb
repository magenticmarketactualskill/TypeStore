# frozen_string_literal: true

class ShapeVersion < ApplicationRecord
  include SemanticVersioning

  # Associations
  belongs_to :data_shape
  belongs_to :published_by, class_name: 'User', optional: true

  # Validations
  validates :version, presence: true, uniqueness: { scope: :data_shape_id }
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

  # Delegate namespace and format access
  delegate :namespace, :format, to: :data_shape

  # Returns the full reference string
  def ref
    "#{data_shape.ref}@#{version}"
  end

  # Check if published
  def published?
    published_at.present?
  end

  # Publish the version
  def publish!(user)
    update!(published_at: Time.current, published_by: user)
    data_shape.update!(current_version: self)
  end

  # Get the content as JSON Schema (if applicable)
  def as_json_schema
    return content if data_shape.json_schema?

    raise "Cannot convert #{data_shape.format} to JSON Schema"
  end

  # Get raw content (for non-JSON formats like SHACL/Turtle)
  def raw
    raw_content.presence || content.to_json
  end

  private

  def compute_content_hash
    self.content_hash = Digest::SHA256.hexdigest(content.to_json)
  end
end
