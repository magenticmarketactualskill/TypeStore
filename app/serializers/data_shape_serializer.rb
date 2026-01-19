# frozen_string_literal: true

class DataShapeSerializer
  def initialize(shape)
    @shape = shape
  end

  def as_json
    {
      id: @shape.id,
      ref: @shape.ref,
      name: @shape.name,
      slug: @shape.slug,
      format: @shape.format,
      description: @shape.description,
      deprecated: @shape.deprecated,
      current_version: @shape.current_version&.version,
      version_count: @shape.versions.size,
      tags: @shape.tag_names,
      namespace: {
        slug: @shape.namespace.display_slug,
        name: @shape.namespace.name
      },
      created_at: @shape.created_at,
      updated_at: @shape.updated_at
    }
  end
end
