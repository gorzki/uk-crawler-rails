Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  resources :exports, only: [:index, :create]
  root to: 'exports#index'
end
