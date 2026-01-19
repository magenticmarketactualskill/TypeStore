# frozen_string_literal: true

module Api
  module V1
    class DataShapesController < BaseController
      before_action :set_namespace
      before_action :set_data_shape, only: [:show, :update, :destroy]
      before_action :authorize_write!, only: [:create, :update, :destroy]

      def action_allows_anonymous?
        action_name.in?(%w[index show])
      end

      # GET /api/v1/namespaces/:namespace_slug/shapes
      def index
        shapes = @namespace.data_shapes
        shapes = shapes.by_format(params[:format]) if params[:format].present?
        shapes = shapes.active unless params[:include_deprecated] == 'true'
        shapes = shapes.tagged_with(params[:tag]) if params[:tag].present?
        shapes = shapes.order(created_at: :desc)

        render_paginated(shapes.includes(:current_version, :tags), serializer: DataShapeSerializer)
      end

      # GET /api/v1/namespaces/:namespace_slug/shapes/:slug
      def show
        render_success(data_shape_response(@data_shape))
      end

      # POST /api/v1/namespaces/:namespace_slug/shapes
      def create
        @data_shape = @namespace.data_shapes.build(data_shape_params)

        if @data_shape.save
          # Create initial version if content provided
          if params[:data_shape][:content].present?
            @data_shape.create_version(
              content: params[:data_shape][:content],
              version: params[:data_shape][:version] || '1.0.0',
              changelog: params[:data_shape][:changelog],
              published_by: current_user
            )
          end

          AuditLog.record(auditable: @data_shape, user: current_user, action: 'create', request: request)
          render_created(data_shape_response(@data_shape.reload))
        else
          render json: { error: 'Unprocessable Entity', details: @data_shape.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/namespaces/:namespace_slug/shapes/:slug
      def update
        if @data_shape.update(data_shape_params)
          AuditLog.record(auditable: @data_shape, user: current_user, action: 'update', request: request)
          render_success(data_shape_response(@data_shape))
        else
          render json: { error: 'Unprocessable Entity', details: @data_shape.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/namespaces/:namespace_slug/shapes/:slug
      def destroy
        @data_shape.destroy!
        AuditLog.record(auditable: @data_shape, user: current_user, action: 'delete', request: request)
        head :no_content
      end

      private

      def set_namespace
        @namespace = Namespace.find_by!(slug: params[:namespace_slug])

        unless @namespace.accessible_by?(current_user)
          render json: { error: 'Forbidden', message: 'Access denied' }, status: :forbidden
        end
      end

      def set_data_shape
        @data_shape = @namespace.data_shapes.find_by!(slug: params[:slug])
      end

      def authorize_write!
        unless @namespace.writable_by?(current_user)
          render json: { error: 'Forbidden', message: 'Write access required' }, status: :forbidden
        end
      end

      def data_shape_params
        params.require(:data_shape).permit(:name, :slug, :format, :description, tag_names: [])
      end

      def data_shape_response(shape)
        {
          id: shape.id,
          ref: shape.ref,
          name: shape.name,
          slug: shape.slug,
          format: shape.format,
          description: shape.description,
          deprecated: shape.deprecated,
          deprecation_message: shape.deprecation_message,
          current_version: shape.current_version&.version,
          version_count: shape.versions.count,
          tags: shape.tag_names,
          namespace: {
            slug: shape.namespace.display_slug,
            name: shape.namespace.name
          },
          content: shape.current_version&.content,
          created_at: shape.created_at,
          updated_at: shape.updated_at
        }
      end
    end
  end
end
