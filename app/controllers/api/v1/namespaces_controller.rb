# frozen_string_literal: true

module Api
  module V1
    class NamespacesController < BaseController
      before_action :set_namespace, only: [:show, :update, :destroy]
      before_action :authorize_write!, only: [:update, :destroy]

      def action_allows_anonymous?
        action_name.in?(%w[index show])
      end

      # GET /api/v1/namespaces
      def index
        namespaces = Namespace.visible_to(current_user)
        namespaces = namespaces.where(visibility: params[:visibility]) if params[:visibility].present?
        namespaces = namespaces.order(created_at: :desc)

        render_paginated(namespaces)
      end

      # GET /api/v1/namespaces/:slug
      def show
        render_success(namespace_response(@namespace))
      end

      # POST /api/v1/namespaces
      def create
        @namespace = Namespace.new(namespace_params)
        @namespace.owner = current_user

        if @namespace.save
          AuditLog.record(auditable: @namespace, user: current_user, action: 'create', request: request)
          render_created(namespace_response(@namespace))
        else
          render json: { error: 'Unprocessable Entity', details: @namespace.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/namespaces/:slug
      def update
        if @namespace.update(namespace_params)
          AuditLog.record(auditable: @namespace, user: current_user, action: 'update', request: request)
          render_success(namespace_response(@namespace))
        else
          render json: { error: 'Unprocessable Entity', details: @namespace.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/namespaces/:slug
      def destroy
        @namespace.destroy!
        AuditLog.record(auditable: @namespace, user: current_user, action: 'delete', request: request)
        head :no_content
      end

      private

      def set_namespace
        @namespace = Namespace.find_by!(slug: params[:slug])

        unless @namespace.accessible_by?(current_user)
          render json: { error: 'Forbidden', message: 'Access denied' }, status: :forbidden
        end
      end

      def authorize_write!
        unless @namespace.writable_by?(current_user)
          render json: { error: 'Forbidden', message: 'Write access required' }, status: :forbidden
        end
      end

      def namespace_params
        params.require(:namespace).permit(:name, :slug, :description, :visibility)
      end

      def namespace_response(namespace)
        {
          id: namespace.id,
          name: namespace.name,
          slug: namespace.display_slug,
          description: namespace.description,
          visibility: namespace.visibility,
          owner_type: namespace.owner_type,
          owner_id: namespace.owner_id,
          type_definitions_count: namespace.type_definitions.count,
          data_shapes_count: namespace.data_shapes.count,
          api_specs_count: namespace.api_specs.count,
          created_at: namespace.created_at,
          updated_at: namespace.updated_at
        }
      end
    end
  end
end
