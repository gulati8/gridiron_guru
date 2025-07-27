Rails.application.routes.draw do
  # Root route - home page
  root 'home#index'

  # Position-specific player routes
  get '/quarterbacks', to: 'players#index', defaults: { position: 'QB' }
  get '/running-backs', to: 'players#index', defaults: { position: 'RB' }
  get '/wide-receivers', to: 'players#index', defaults: { position: 'WR' }
  get '/tight-ends', to: 'players#index', defaults: { position: 'TE' }

  # Player detail routes by position
  get '/quarterbacks/:id', to: 'players#show', defaults: { position: 'QB' }
  get '/running-backs/:id', to: 'players#show', defaults: { position: 'RB' }
  get '/wide-receivers/:id', to: 'players#show', defaults: { position: 'WR' }
  get '/tight-ends/:id', to: 'players#show', defaults: { position: 'TE' }

  # Import routes
  resources :imports, only: [:index] do
    collection do
      get :pro_football_reference_player_stats
      post :import_pro_football_reference_stats
      post :bulk_import_pro_football_reference_stats
    end
  end

  # Analytics routes - RESTful (keeping for backward compatibility)
  resources :analytics, only: [:index, :show] do
    collection do
      get :rankings  # /analytics/rankings
      get :teams     # /analytics/teams
    end
  end

  # Sidekiq monitoring (if you want to see background jobs)
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
