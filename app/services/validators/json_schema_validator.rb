# frozen_string_literal: true

module Validators
  class JsonSchemaValidator
    def initialize(schema)
      @schema = schema
      @validator = JSONSchemer.schema(schema)
    end

    def validate(data, options = {})
      errors = @validator.validate(data).to_a

      {
        valid: errors.empty?,
        errors: errors.map { |e| format_error(e) },
        warnings: extract_warnings(data, options)
      }
    end

    private

    def format_error(error)
      {
        path: error['data_pointer'],
        schema_path: error['schema_pointer'],
        message: build_error_message(error),
        keyword: error['type'],
        details: error['details']
      }
    end

    def build_error_message(error)
      case error['type']
      when 'required'
        "Missing required property: #{error['details']['missing_keys'].join(', ')}"
      when 'type'
        "Expected #{error['schema']['type']}, got #{error['data'].class.name.downcase}"
      when 'enum'
        "Value must be one of: #{error['schema']['enum'].join(', ')}"
      when 'pattern'
        "Value does not match pattern: #{error['schema']['pattern']}"
      when 'minLength'
        "String is too short (minimum #{error['schema']['minLength']} characters)"
      when 'maxLength'
        "String is too long (maximum #{error['schema']['maxLength']} characters)"
      when 'minimum'
        "Value is below minimum: #{error['schema']['minimum']}"
      when 'maximum'
        "Value is above maximum: #{error['schema']['maximum']}"
      when 'format'
        "Invalid format for #{error['schema']['format']}"
      else
        error['error'] || "Validation failed: #{error['type']}"
      end
    end

    def extract_warnings(data, options)
      warnings = []

      # Check for deprecated fields
      if options[:check_deprecated] && @schema['x-deprecated-fields']
        @schema['x-deprecated-fields'].each do |field|
          if data.is_a?(Hash) && data.key?(field)
            warnings << {
              path: "/#{field}",
              message: "Field '#{field}' is deprecated",
              type: 'deprecation'
            }
          end
        end
      end

      # Check for unknown properties in strict mode
      if options[:strict] && @schema['additionalProperties'] == false
        schema_props = @schema['properties']&.keys || []
        data_props = data.is_a?(Hash) ? data.keys : []
        unknown = data_props - schema_props

        unknown.each do |prop|
          warnings << {
            path: "/#{prop}",
            message: "Unknown property: #{prop}",
            type: 'additional_property'
          }
        end
      end

      warnings
    end
  end
end
