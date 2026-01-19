# frozen_string_literal: true

class SchemaResolver
  class NotFoundError < StandardError; end

  # Schema reference format: @namespace/type/slug@version
  # Examples:
  #   @company/shapes/customer-record
  #   @company/shapes/customer-record@1.0.0
  #   @company/shapes/customer-record@^1.0
  #   @company/types/email-address@latest
  REF_PATTERN = %r{^(@[a-z0-9-]+)/(\w+)/([a-z0-9-]+)(?:@(.+))?$}i

  def resolve(ref, format: nil)
    match = ref.match(REF_PATTERN)
    raise NotFoundError, "Invalid schema reference: #{ref}" unless match

    namespace_slug, schema_type, slug, version_constraint = match.captures

    # Find namespace
    namespace = Namespace.find_by(slug: namespace_slug)
    raise NotFoundError, "Namespace not found: #{namespace_slug}" unless namespace

    # Find schema based on type
    schema = find_schema(namespace, schema_type, slug)
    raise NotFoundError, "Schema not found: #{ref}" unless schema

    # Resolve version
    version = resolve_version(schema, version_constraint)
    raise NotFoundError, "Version not found: #{ref}" unless version

    # Build response
    {
      ref: version.ref,
      schema_type: schema.class.name,
      schema_id: schema.id,
      version_id: version.id,
      version: version.version,
      content: version.content,
      raw_content: version.respond_to?(:raw_content) ? version.raw_content : nil,
      format: determine_format(schema, format),
      dependencies: extract_dependencies(version)
    }
  end

  def resolve_multiple(refs, format: nil)
    refs.map do |ref|
      begin
        [ref, resolve(ref, format: format)]
      rescue NotFoundError => e
        [ref, { error: e.message }]
      end
    end.to_h
  end

  private

  def find_schema(namespace, schema_type, slug)
    case schema_type.downcase
    when 'types'
      namespace.type_definitions.find_by(slug: slug)
    when 'shapes'
      namespace.data_shapes.find_by(slug: slug)
    when 'apis'
      namespace.api_specs.find_by(slug: slug)
    end
  end

  def resolve_version(schema, constraint)
    return schema.latest_version if constraint.blank? || constraint == 'latest'

    schema.resolve_version(constraint)
  end

  def determine_format(schema, requested_format)
    return requested_format if requested_format.present?

    case schema
    when DataShape
      schema.format
    when TypeDefinition
      'json_schema'
    when ApiSpec
      schema.spec_type
    end
  end

  def extract_dependencies(version)
    parent = version.respond_to?(:data_shape) ? version.data_shape :
             version.respond_to?(:type_definition) ? version.type_definition :
             version.respond_to?(:api_spec) ? version.api_spec : nil

    return [] unless parent

    parent.source_references.map do |ref|
      {
        type: ref.reference_type,
        target_ref: "#{ref.target.namespace.display_slug}/#{ref.target_type.underscore.pluralize}/#{ref.target.slug}",
        path: ref.reference_path
      }
    end
  end
end
