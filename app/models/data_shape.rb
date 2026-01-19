# frozen_string_literal: true

class DataShape < ApplicationRecord
  include Taggable
  include Versionable

  FORMATS = %w[json_schema json_ld shacl avro protobuf xml_schema].freeze

  # Associations
  belongs_to :namespace
  belongs_to :current_version, class_name: 'ShapeVersion', optional: true
  has_many :versions, class_name: 'ShapeVersion', dependent: :destroy
  has_many :source_references, as: :source, class_name: 'SchemaReference', dependent: :destroy
  has_many :target_references, as: :target, class_name: 'SchemaReference', dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :namespace_id }
  validates :format, presence: true, inclusion: { in: FORMATS }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Scopes
  scope :active, -> { where(deprecated: false) }
  scope :deprecated, -> { where(deprecated: true) }
  scope :by_format, ->(fmt) { where(format: fmt) }
  scope :json_schemas, -> { by_format('json_schema') }
  scope :shacl_shapes, -> { by_format('shacl') }
  scope :json_ld_contexts, -> { by_format('json_ld') }

  # Returns the full reference string: @namespace/shapes/slug
  def ref
    "#{namespace.display_slug}/shapes/#{slug}"
  end

  # Returns reference with version: @namespace/shapes/slug@1.0.0
  def ref_with_version(version = nil)
    version ||= current_version&.version
    version ? "#{ref}@#{version}" : ref
  end

  # Deprecate with message
  def deprecate!(message = nil)
    update!(deprecated: true, deprecation_message: message)
  end

  # Get version by semver string
  def version(semver)
    versions.find_by(version: semver)
  end

  # Get latest version
  def latest_version
    current_version || versions.order(version_major: :desc, version_minor: :desc, version_patch: :desc).first
  end

  # Check if this is a JSON Schema
  def json_schema?
    format == 'json_schema'
  end

  # Check if this is a SHACL shape
  def shacl?
    format == 'shacl'
  end

  # Check if this is JSON-LD
  def json_ld?
    format == 'json_ld'
  end

  private

  def generate_slug
    return if slug.present?

    self.slug = name.to_s.parameterize
  end
end
