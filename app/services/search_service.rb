# frozen_string_literal: true

class SearchService
  def search(query, filters: {}, page: 1, per_page: 20)
    results = []

    # Search data shapes
    if filters[:type].nil? || filters[:type] == 'data_shape'
      shapes = search_data_shapes(query, filters)
      results.concat(shapes.map { |s| format_result(s, 'data_shape') })
    end

    # Search type definitions
    if filters[:type].nil? || filters[:type] == 'type_definition'
      types = search_type_definitions(query, filters)
      results.concat(types.map { |t| format_result(t, 'type_definition') })
    end

    # Search API specs
    if filters[:type].nil? || filters[:type] == 'api_spec'
      apis = search_api_specs(query, filters)
      results.concat(apis.map { |a| format_result(a, 'api_spec') })
    end

    # Sort by relevance (simple implementation)
    results.sort_by! { |r| -r[:score] }

    # Paginate
    total_count = results.size
    offset = (page.to_i - 1) * per_page.to_i
    paginated = results[offset, per_page.to_i] || []

    {
      items: paginated,
      meta: {
        current_page: page.to_i,
        per_page: per_page.to_i,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page.to_i).ceil
      }
    }
  end

  def semantic_search(query, filters: {}, limit: 10)
    # Placeholder for semantic search with embeddings
    # In production, this would use pgvector and LLM embeddings
    search(query, filters: filters, page: 1, per_page: limit)[:items]
  end

  private

  def search_data_shapes(query, filters)
    scope = DataShape.includes(:namespace, :current_version, :tags)
    scope = apply_common_filters(scope, filters)
    scope = scope.by_format(filters[:format]) if filters[:format].present?

    # Simple text search
    scope.where(
      'data_shapes.name ILIKE :q OR data_shapes.slug ILIKE :q OR data_shapes.description ILIKE :q',
      q: "%#{query}%"
    ).limit(50)
  end

  def search_type_definitions(query, filters)
    scope = TypeDefinition.includes(:namespace, :current_version, :tags)
    scope = apply_common_filters(scope, filters)

    scope.where(
      'type_definitions.name ILIKE :q OR type_definitions.slug ILIKE :q OR type_definitions.description ILIKE :q',
      q: "%#{query}%"
    ).limit(50)
  end

  def search_api_specs(query, filters)
    scope = ApiSpec.includes(:namespace, :current_version, :tags)
    scope = apply_common_filters(scope, filters)

    scope.where(
      'api_specs.name ILIKE :q OR api_specs.slug ILIKE :q OR api_specs.description ILIKE :q',
      q: "%#{query}%"
    ).limit(50)
  end

  def apply_common_filters(scope, filters)
    if filters[:namespace].present?
      namespace = Namespace.find_by(slug: filters[:namespace])
      scope = scope.where(namespace: namespace) if namespace
    end

    if filters[:tags].present?
      scope = scope.tagged_with_any(Array(filters[:tags]))
    end

    scope.active
  end

  def format_result(record, type)
    score = calculate_score(record)

    {
      type: type,
      ref: record.ref,
      name: record.name,
      slug: record.slug,
      description: record.description,
      namespace: record.namespace.display_slug,
      current_version: record.current_version&.version,
      deprecated: record.deprecated,
      tags: record.tag_names,
      format: record.respond_to?(:format) ? record.format : nil,
      spec_type: record.respond_to?(:spec_type) ? record.spec_type : nil,
      category: record.respond_to?(:category) ? record.category : nil,
      score: score,
      updated_at: record.updated_at
    }
  end

  def calculate_score(record)
    score = 0
    score += 10 if record.current_version.present?
    score += 5 unless record.deprecated
    score += record.versions.count.clamp(0, 10)
    score
  end
end
