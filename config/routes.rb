Rails.application.routes.draw do
  devise_for :users,
             path: "api/v1/auth",
             path_names: {
               sign_in: "login",
               sign_out: "logout"
             },
             skip: [ :registrations ],
             controllers: {
               sessions: "api/v1/auth/sessions"
             }

  post "/api/v1/payments/webhook",
     to: "api/v1/payments_webhook#create"

  namespace :api do
    namespace :v1 do
      resources :products, only: %i[index show create update destroy]
      resources :categories
      resources :orders, only: %i[index create show update] do
        member do
          post :confirm
          post :process_order, path: :process
          post :ship
          post :deliver
          post :cancel
        end
        resources :payments, only: :create
      end
      resources :customers, only: %i[index show update] do
        member do
          get :orders
        end
      end
      namespace :auth do
        get "me", to: "me#show"
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
