# frozen_string_literal: true

module Api
  module V1
    class ShapeVersionsController < BaseController
      before_action :set_namespace
      before_action :set_data_shape
      before_action :set_version, only: [:show]
      before_action :authorize_write!, only: [:create]

      def action_allows_anonymous?
        action_name.in?(%w[index show])
      end

      # GET /api/v1/namespaces/:namespace_slug/shapes/:shape_slug/versions
      def index
        versions = @data_shape.versions.ordered

        render_success(versions.map { |v| version_response(v) })
      end

      # GET /api/v1/namespaces/:namespace_slug/shapes/:shape_slug/versions/:version
      def show
        render_success(version_response(@version, include_content: true))
      end

      # POST /api/v1/namespaces/:namespace_slug/shapes/:shape_slug/versions
      def create
        @version = @data_shape.versions.build(version_params)
        @version.published_by = current_user

        if @version.save
          # Publish and set as current if requested
          @version.publish!(current_user) if params[:publish] != false

          AuditLog.record(auditable: @version, user: current_user, action: 'version_created', request: request)
          render_created(version_response(@version, include_content: true))
        else
          render json: { error: 'Unprocessable Entity', details: @version.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_namespace
        @namespace = Namespace.find_by!(slug: params[:namespace_slug])

        unless @namespace.accessible_by?(current_user)
          render json: { error: 'Forbidden', message: 'Access denied' }, status: :forbidden
        end
      end

      def set_data_shape
        @data_shape = @namespace.data_shapes.find_by!(slug: params[:shape_slug])
      end

      def set_version
        @version = @data_shape.versions.find_by!(version: params[:version])
      end

      def authorize_write!
        unless @namespace.writable_by?(current_user)
          render json: { error: 'Forbidden', message: 'Write access required' }, status: :forbidden
        end
      end

      def version_params
        params.require(:version).permit(:version, :changelog).tap do |p|
          p[:content] = params[:version][:content] if params[:version][:content].present?
        end
      end

      def version_response(version, include_content: false)
        response = {
          version: version.version,
          ref: version.ref,
          version_major: version.version_major,
          version_minor: version.version_minor,
          version_patch: version.version_patch,
          published: version.published?,
          published_at: version.published_at,
          published_by: version.published_by&.name,
          changelog: version.changelog,
          git_sha: version.git_sha,
          content_hash: version.content_hash,
          created_at: version.created_at
        }

        response[:content] = version.content if include_content
        response[:raw_content] = version.raw_content if include_content && version.raw_content.present?

        response
      end
    end
  end
end
