# frozen_string_literal: true

class ValidationService
  class SchemaNotFoundError < StandardError; end
  class UnsupportedFormatError < StandardError; end

  ValidationResult = Struct.new(:valid?, :errors, :warnings, :schema_ref, keyword_init: true)

  VALIDATORS = {
    'json_schema' => 'Validators::JsonSchemaValidator',
    'shacl' => 'Validators::ShaclValidator',
    'json_ld' => 'Validators::JsonLdValidator'
  }.freeze

  def initialize
    @resolver = SchemaResolver.new
  end

  def validate(schema_ref:, data:, options: {})
    # Resolve the schema
    resolved = @resolver.resolve(schema_ref)
    raise SchemaNotFoundError, "Schema not found: #{schema_ref}" unless resolved

    # Check cache
    unless options[:skip_cache]
      cached = check_cache(resolved, data)
      return cached if cached
    end

    # Get validator
    validator_class = VALIDATORS[resolved[:format]]
    raise UnsupportedFormatError, "Unsupported format: #{resolved[:format]}" unless validator_class

    # Perform validation
    validator = validator_class.constantize.new(resolved[:content])
    result = validator.validate(data, options)

    # Cache result
    cache_result(resolved, data, result) unless options[:skip_cache]

    ValidationResult.new(
      valid?: result[:valid],
      errors: result[:errors] || [],
      warnings: result[:warnings] || [],
      schema_ref: schema_ref
    )
  end

  def validate_batch(validations)
    validations.map do |v|
      {
        schema_ref: v[:schema_ref],
        result: validate(
          schema_ref: v[:schema_ref],
          data: v[:data],
          options: v[:options] || {}
        )
      }
    end
  end

  private

  def check_cache(resolved, data)
    cached = ValidationCache.find_cached(
      schema_type: resolved[:schema_type],
      schema_id: resolved[:schema_id],
      schema_version_id: resolved[:version_id],
      data_hash: ValidationCache.compute_data_hash(data)
    )

    return nil unless cached

    ValidationResult.new(
      valid?: cached.is_valid,
      errors: cached.errors || [],
      warnings: [],
      schema_ref: resolved[:ref]
    )
  end

  def cache_result(resolved, data, result)
    ValidationCache.cache_result(
      schema_type: resolved[:schema_type],
      schema_id: resolved[:schema_id],
      schema_version_id: resolved[:version_id],
      data: data,
      is_valid: result[:valid],
      errors: result[:errors]
    )
  rescue StandardError => e
    Rails.logger.warn("Failed to cache validation result: #{e.message}")
  end
end
