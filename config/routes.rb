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

  namespace :api do
    namespace :v1 do
      resources :products, only: %i[index show create update destroy]
      namespace :auth do
        get "me", to: "me#show"
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
