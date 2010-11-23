Katalog::Application.routes.draw do
  get "index/title"

  resources :container_types

  devise_for :users

  resources :locations

  resources :dossiers, :topics, :topic_groups do
    collection do
      get :search
    end

    resources :containers
  end

  post "dossier_numbers/set_amount"
  
  resources :keywords do
    collection do
      get :search
    end
  end

  root :to => "dossiers#index"
end
