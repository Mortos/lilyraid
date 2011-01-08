Lilyraid::Application.routes.draw do
  resources :lists
  resource :calendar
  resources :accounts do
    resources :characters do
      member do
    get :roles
      end
    end
  end

  resources :raids do
    resources :signups do
      member do
        post :preferred
      end
    end

    resources :accounts do
      resources :raider_tags
    end

    resources :loots
    resources :locations
    resources :slots do
      collection do
        put :wait_list
      end
    end
  end

  namespace :admin do
    resources :characters
    resources :templates
    resources :instances
    resources :accounts do
      collection do
        post :rename
      end
    end
    resources :tags
  end

  match 'wowhead/:search' => 'loots#search', :as => :wowhead
  match 'roles/:id' => 'characters#roles'

  match 'login' => 'login#index', :as => :login, :via => get
  match 'login' => 'login#login', :as => :login_post, :via => post
  match 'logout' => 'login#logout', :as => :logout, :via => get

  match '/' => 'raids#index'
end
