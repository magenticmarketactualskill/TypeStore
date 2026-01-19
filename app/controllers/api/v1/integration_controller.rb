# frozen_string_literal: true

module Api
  module V1
    class IntegrationController < BaseController
      # POST /api/v1/integration/resolve
      # Resolve schema reference(s) for CollaborativeKanBan integration
      def resolve
        refs = Array(params[:refs])
        include_dependencies = params[:include_dependencies] == true
        format = params[:format]

        unless refs.present?
          return render json: { error: 'Bad Request', message: 'refs is required' }, status: :bad_request
        end

        schemas = refs.each_with_object({}) do |ref, result|
          resolved = SchemaResolver.new.resolve(ref, format: format)
          next unless resolved

          result[ref] = {
            ref: ref,
            resolved_version: resolved[:version],
            content: resolved[:content],
            format: resolved[:format]
          }

          if include_dependencies
            result[ref][:dependencies] = resolved[:dependencies]
          end
        end

        render_success({ schemas: schemas })
      rescue SchemaResolver::NotFoundError => e
        render json: { error: 'Not Found', message: e.message }, status: :not_found
      end

      # POST /api/v1/integration/validate
      # Validate transformation step data
      def validate
        input_schema = params[:input_schema]
        output_schema = params[:output_schema]
        input_data = params[:input_data]
        output_data = params[:output_data]

        results = {}

        # Validate input
        if input_schema.present? && input_data.present?
          results[:input_validation] = validate_data(input_schema, input_data)
        end

        # Validate output
        if output_schema.present? && output_data.present?
          results[:output_validation] = validate_data(output_schema, output_data)
        end

        render_success(results)
      end

      # POST /api/v1/integration/validate-graph
      # Validate knowledge graph against SHACL shapes
      def validate_graph
        shapes_ref = params[:shapes_ref]
        graph = params[:graph]

        unless shapes_ref.present? && graph.present?
          return render json: { error: 'Bad Request', message: 'shapes_ref and graph are required' }, status: :bad_request
        end

        result = ShaclValidationService.new.validate_graph(
          shapes_ref: shapes_ref,
          graph: graph,
          subset: params[:subset]
        )

        render_success(result)
      rescue ShaclValidationService::Error => e
        render json: { error: 'Validation Error', message: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/integration/infer-type
      # Infer schema type from data samples
      def infer_type
        samples = params[:samples]
        target_format = params[:target_format] || 'json_schema'
        context = (params[:context] || {}).to_h.symbolize_keys

        unless samples.present? && samples.is_a?(Array)
          return render json: { error: 'Bad Request', message: 'samples array is required' }, status: :bad_request
        end

        result = SchemaInferenceService.new.infer(
          samples: samples,
          target_format: target_format,
          context: context
        )

        render_success(result)
      end

      # POST /api/v1/integration/suggest
      # Suggest schemas based on card context
      def suggest
        card_description = params[:card_description]
        project_domain = params[:project_domain]
        existing_schemas = params[:existing_schemas] || []
        data_samples = params[:data_samples] || []

        result = SchemaSuggestionService.new.suggest(
          description: card_description,
          domain: project_domain,
          existing: existing_schemas,
          samples: data_samples
        )

        render_success(result)
      end

      private

      def validate_data(schema_ref, data)
        result = ValidationService.new.validate(
          schema_ref: schema_ref,
          data: data
        )

        {
          valid: result.valid?,
          errors: result.errors,
          warnings: result.warnings
        }
      rescue StandardError => e
        {
          valid: false,
          errors: [{ message: e.message }],
          warnings: []
        }
      end
    end
  end
end
