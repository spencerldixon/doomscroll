Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  devise_scope :user do
    unauthenticated do
      root to: "root#index"
    end

    authenticated do
      root to: "issues#index", as: :authenticated_root
    end
  end


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "onboarding/complete", to: "onboarding#complete", as: :onboarding_complete
  resources :onboarding, only: [ :show, :update ]

  resources :issues, only: [ :index, :show ]
  resource :preferences, only: [ :show, :update ]
  resources :feeds, only: [ :index, :create ] do
    post :import_opml, on: :collection
  end
  resources :user_feeds, only: [ :create, :destroy ], param: :feed_id

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
