Rails.application.routes.draw do
  mount RailsEventStore::Browser => "/res" if Rails.env.development?
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  # namespace :api, defaults: { format: JSON } do
  #   namespace :v1 do
  #   end
  # end
  devise_for :users, path: "", path_names: {
    sign_in: "api/v1/login",
    sign_out: "api/v1/logout",
    registration: "api/v1/signup"
  },
  controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  mount ActionCable.server => "/cable"

  namespace :api do
    namespace :v1 do
      get "/messages/:id", to: "messages#show"
      resource :messages, only: [ :update ]
      authenticate do
        get "/receive", to: "receive#index"
      end
    end
  end
end
