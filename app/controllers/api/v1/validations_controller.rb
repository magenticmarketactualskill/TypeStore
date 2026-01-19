# frozen_string_literal: true

module Api
  module V1
    class ValidationsController < BaseController
      def action_allows_anonymous?
        true # Validation can be public
      end

      # POST /api/v1/validate
      def create
        schema_ref = params[:schema_ref]
        data = params[:data]
        options = params[:options] || {}

        unless schema_ref.present? && data.present?
          return render json: { error: 'Bad Request', message: 'schema_ref and data are required' }, status: :bad_request
        end

        # Convert ActionController::Parameters to a plain hash
        data_hash = data.respond_to?(:to_unsafe_h) ? data.to_unsafe_h : data

        result = ValidationService.new.validate(
          schema_ref: schema_ref,
          data: data_hash,
          options: options.to_h.symbolize_keys
        )

        render_success(validation_response(result))
      rescue ValidationService::SchemaNotFoundError => e
        render json: { error: 'Not Found', message: e.message }, status: :not_found
      rescue ValidationService::UnsupportedFormatError => e
        render json: { error: 'Unprocessable Entity', message: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/validate/batch
      def batch
        validations = params[:validations]

        unless validations.is_a?(Array) && validations.present?
          return render json: { error: 'Bad Request', message: 'validations array is required' }, status: :bad_request
        end

        results = ValidationService.new.validate_batch(
          validations.map do |v|
            {
              schema_ref: v[:schema_ref],
              data: v[:data],
              options: (v[:options] || {}).to_h.symbolize_keys
            }
          end
        )

        render_success(results.map { |r| { schema_ref: r[:schema_ref], result: validation_response(r[:result]) } })
      end

      private

      def validation_response(result)
        {
          valid: result.valid?,
          errors: result.errors,
          warnings: result.warnings,
          schema_ref: result.schema_ref,
          validated_at: Time.current
        }
      end
    end
  end
end
