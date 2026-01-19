# frozen_string_literal: true

class SchemaReference < ApplicationRecord
  REFERENCE_TYPES = %w[uses extends implements imports embeds].freeze

  # Polymorphic associations
  belongs_to :source, polymorphic: true
  belongs_to :target, polymorphic: true

  # Validations
  validates :source_type, presence: true, inclusion: { in: %w[TypeDefinition DataShape ApiSpec] }
  validates :target_type, presence: true, inclusion: { in: %w[TypeDefinition DataShape ApiSpec] }
  validates :reference_type, presence: true, inclusion: { in: REFERENCE_TYPES }

  # Scopes
  scope :uses, -> { where(reference_type: 'uses') }
  scope :extends, -> { where(reference_type: 'extends') }
  scope :implements, -> { where(reference_type: 'implements') }
  scope :imports, -> { where(reference_type: 'imports') }
  scope :embeds, -> { where(reference_type: 'embeds') }

  scope :from_type, ->(type) { where(source_type: type) }
  scope :to_type, ->(type) { where(target_type: type) }

  # Get all dependencies (what this schema uses)
  def self.dependencies_of(schema)
    where(source: schema)
  end

  # Get all dependents (what uses this schema)
  def self.dependents_of(schema)
    where(target: schema)
  end

  # Build reference from a schema and target ref string
  def self.create_from_ref(source:, target_ref:, reference_type:, path: nil)
    target = resolve_ref(target_ref)
    return nil unless target

    create!(
      source: source,
      target: target,
      reference_type: reference_type,
      reference_path: path
    )
  end

  # Resolve a reference string to a schema object
  def self.resolve_ref(ref_string)
    # Parse ref: @namespace/types/slug@version
    match = ref_string.match(%r{^(@[a-z0-9-]+)/(\w+)/([a-z0-9-]+)(?:@(.+))?$}i)
    return nil unless match

    namespace_slug, schema_type, slug, _version = match.captures
    namespace = Namespace.find_by(slug: namespace_slug)
    return nil unless namespace

    case schema_type
    when 'types'
      namespace.type_definitions.find_by(slug: slug)
    when 'shapes'
      namespace.data_shapes.find_by(slug: slug)
    when 'apis'
      namespace.api_specs.find_by(slug: slug)
    end
  end
end
