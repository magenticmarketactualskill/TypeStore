Rails.application.routes.draw do
  # Devise routes for authentication
  devise_for :users, skip: [:sessions, :registrations]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API v1
  namespace :api do
    namespace :v1 do
      # Namespaces
      resources :namespaces, param: :slug, only: [:index, :show, :create, :update, :destroy] do
        # Data Shapes
        resources :shapes, controller: 'data_shapes', param: :slug, only: [:index, :show, :create, :update, :destroy] do
          resources :versions, controller: 'shape_versions', param: :version, only: [:index, :show, :create]
        end

        # Type Definitions
        resources :types, controller: 'type_definitions', param: :slug, only: [:index, :show, :create, :update, :destroy] do
          resources :versions, controller: 'type_versions', param: :version, only: [:index, :show, :create]
        end

        # API Specs
        resources :apis, controller: 'api_specs', param: :slug, only: [:index, :show, :create, :update, :destroy] do
          resources :versions, controller: 'api_spec_versions', param: :version, only: [:index, :show, :create]
        end
      end

      # Validation
      post 'validate', to: 'validations#create'
      post 'validate/batch', to: 'validations#batch'

      # Search
      get 'search', to: 'search#index'
      post 'search/semantic', to: 'search#semantic'

      # Schema Resolution
      post 'resolve', to: 'integration#resolve'

      # Integration API (for CollaborativeKanBan)
      namespace :integration do
        post 'resolve', to: '/api/v1/integration#resolve'
        post 'validate', to: '/api/v1/integration#validate'
        post 'validate-graph', to: '/api/v1/integration#validate_graph'
        post 'infer-type', to: '/api/v1/integration#infer_type'
        post 'suggest', to: '/api/v1/integration#suggest'
      end
    end
  end

  # Root path - API info
  root to: proc { [200, { 'Content-Type' => 'application/json' }, [{
    name: 'TypeStore API',
    version: '1.0.0',
    documentation: '/api/v1',
    endpoints: {
      namespaces: '/api/v1/namespaces',
      validate: '/api/v1/validate',
      search: '/api/v1/search'
    }
  }.to_json]] }
end
