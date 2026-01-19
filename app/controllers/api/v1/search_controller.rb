# frozen_string_literal: true

module Api
  module V1
    class SearchController < BaseController
      def action_allows_anonymous?
        true # Search is public for public schemas
      end

      # GET /api/v1/search
      def index
        query = params[:q]

        unless query.present?
          return render json: { error: 'Bad Request', message: 'Query parameter q is required' }, status: :bad_request
        end

        filters = {
          type: params[:type],
          format: params[:format],
          namespace: params[:namespace],
          tags: params[:tags]
        }.compact

        results = SearchService.new.search(
          query,
          filters: filters,
          page: params[:page] || 1,
          per_page: params[:per_page] || 20
        )

        render_success(results[:items], meta: results[:meta])
      end

      # POST /api/v1/search/semantic
      def semantic
        query = params[:query]

        unless query.present?
          return render json: { error: 'Bad Request', message: 'Query is required' }, status: :bad_request
        end

        filters = (params[:filters] || {}).to_h.symbolize_keys
        limit = params[:limit] || 10

        results = SearchService.new.semantic_search(
          query,
          filters: filters,
          limit: limit
        )

        render_success(results)
      end
    end
  end
end
