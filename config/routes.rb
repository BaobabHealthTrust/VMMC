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
  get '/people/region' => 'people#region'
  get '/people/district' => 'people#district'
  get '/people/traditional_authority' => 'people#traditional_authority'
  get '/people/village' => 'people#village'
  get '/people/landmark' => 'people#landmark'
  get '/search_results' => 'people#search_results'
  get '/search_by_identifier' => 'people#search_by_identifier'
  get '/people/new'
  post '/people/create'
  get '/select' => 'people#select'
  post '/select' => 'people#select'
  get '/new_patient' => 'patients#new_patient'
  get '/patients/show/:patient_id' => 'patients#show'
  get '/my_account' => 'clinic#my_account'
  get '/change_password' => 'clinic#change_password'
  get '/my_profile' => 'clinic#my_profile'
  get '/edit_demographics' => 'clinic#edit_demographics'
  get '/overview' => 'clinic#overview'
  get 'report' => 'clinic#report'
  get 'first_report' => 'clinic#first_report'
  get 'second_report' => 'clinic#second_report'
  get 'administration' => 'clinic#administration'
  get 'user' => 'clinic#user'
  get 'manage_location' => 'clinic#manage_location'
  get 'manage_villages' => 'clinic#manage_villages'
  get '/header' => 'patients#header'
  get '/encounters/new' => 'encounters#new'
  get '/vitals' => 'encounters#vitals'
  get '/medical_history' => 'encounters#medical_history'
  get '/hiv_art_status' => 'encounters#hiv_art_status'
  get '/genital_examination' => 'encounters#genital_examination'
  get '/circumcision' => 'encounters#circumcision'
  get '/post_op_review' => 'encounters#post_op_review'
  get '/registration' => 'encounters#registration'
  get '/person_names/given_names' => 'person_names#given_names'
  get '/person_names/family_names' => 'person_names#family_names'
  get '/person_names/middle_name' => 'person_names#middle_name'

  post '/encounters/create'
  post '/patients/get_patient_visits'
  post '/patients/get_patient_vitals'
  get '/patients/get_patient_vitals'
  get '/encounters/details'
  post '/encounters/observations'
  get '/encounters/observations'
  post '/encounters/void'
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
