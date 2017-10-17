Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
   root 'clinic#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

    get '/login' => 'users#login'
    post '/user_authetication' => 'users#user_authetication'
    get '/logout' => 'users#logout'
    get '/set_date' => 'clinic#set_date'
    post '/set_date' => 'clinic#set_date'
    get '/people/search' => 'people#search'
    get '/search_results' => 'people#search_results'
    get '/select' => 'people#select'
    post '/select' => 'people#select'
    get '/new_patient' => 'patients#new_patient'
    get '/my_account' => 'clinic#my_account'
    get '/change_password' => 'clinic#change_password'
    get '/my_profile' => 'clinic#my_profile'
    get '/edit_demographics' => 'clinic#edit_demographics'


  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
