Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq Web UI
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      post "auth/signup", to: "auth#signup"
      post "auth/password/reset", to: "auth#reset_password"

      # Users
      resources :users, only: [ :index, :show, :update, :destroy ]

      # Tasks with nested comments and custom actions
      concern :commentable do
        resources :comments, only: [ :index, :create, :destroy ]
      end

      resources :tasks, concerns: :commentable do
        member do
          post :assign
          post :complete
          post :export
        end

        collection do
          get :dashboard
          get :overdue
        end
      end
    end

    namespace :v2 do
      # V2 API with breaking changes (camelCase responses)
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      post "auth/signup", to: "auth#signup"
      post "auth/password/reset", to: "auth#reset_password"

      resources :users, only: [ :index, :show, :update, :destroy ]

      concern :commentable do
        resources :comments, only: [ :index, :create, :destroy ]
      end

      resources :tasks, concerns: :commentable do
        member do
          post :assign
          post :complete
          post :export
        end

        collection do
          get :dashboard
          get :overdue
        end
      end
    end
  end

  # Custom error handlers
  match "*unmatched", to: "application#route_not_found", via: :all
end
