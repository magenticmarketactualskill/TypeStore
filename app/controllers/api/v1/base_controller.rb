# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Pagy::Backend

      before_action :authenticate_request!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      protected

      def authenticate_request!
        # Try API key first
        api_key = request.headers['X-API-Key'] || params[:api_key]
        if api_key.present?
          @current_user = User.find_by_api_key(api_key)
          return if @current_user
        end

        # Try Bearer token (JWT or session)
        auth_header = request.headers['Authorization']
        if auth_header&.start_with?('Bearer ')
          token = auth_header.split(' ').last
          @current_user = authenticate_token(token)
          return if @current_user
        end

        # For development, allow unauthenticated access to public resources
        return if action_allows_anonymous?

        render_unauthorized
      end

      def current_user
        @current_user
      end

      def action_allows_anonymous?
        # Override in subclasses for public endpoints
        false
      end

      def render_success(data, status: :ok, meta: {})
        response = { data: data }
        response[:meta] = meta if meta.present?
        render json: response, status: status
      end

      def render_created(data)
        render_success(data, status: :created)
      end

      def render_paginated(collection, serializer: nil)
        pagy, records = pagy(collection)

        data = if serializer
                 records.map { |r| serializer.new(r).as_json }
               else
                 records
               end

        render_success(data, meta: pagination_meta(pagy))
      end

      def pagination_meta(pagy)
        {
          current_page: pagy.page,
          total_pages: pagy.pages,
          total_count: pagy.count,
          per_page: pagy.limit
        }
      end

      private

      def authenticate_token(token)
        # Simple token lookup for now
        # In production, this would verify a JWT
        User.find_by(id: token)
      end

      def render_unauthorized
        render json: { error: 'Unauthorized', message: 'Invalid or missing API key' }, status: :unauthorized
      end

      def not_found(exception)
        render json: { error: 'Not Found', message: exception.message }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { error: 'Unprocessable Entity', message: exception.message, details: exception.record&.errors&.full_messages }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: { error: 'Bad Request', message: exception.message }, status: :bad_request
      end
    end
  end
end
