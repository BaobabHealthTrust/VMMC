Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'clinic#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  get '/get_time_left' => 'encounters#get_time_left'
  get '/login' => 'users#login'
  post '/user_authetication' => 'users#user_authetication'
  get '/logout' => 'users#logout'
  get '/set_date' => 'clinic#set_date'
  post '/set_date' => 'clinic#set_date'
  get '/reset_date' => 'clinic#reset_date'
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
  get 'edit_demographics/:patient_id' => 'patients#edit_demographics'
  get '/patients/activities'
  get '/patients/patient_demographics_label'
  get '/patients/national_id_label'
  get '/patients/visit_summary_label'

  get '/patients/get_user_role'
  post '/patients/get_user_role'

  get '/patients/get_demographics'
  post '/patients/get_demographics'
  get '/my_account' => 'users#my_account'
  get '/my_profile' => 'users#my_profile'
  get '/edit_demographics' => 'users#edit_demographics'
  get '/overview' => 'clinic#overview'

  get 'clinic/todays_statistics'
  post 'clinic/todays_statistics'

  get 'clinic/this_months_statistics'
  post 'clinic/this_months_statistics'

  get 'clinic/this_years_statistics'
  post 'clinic/this_years_statistics'

  get 'clinic/todays_registration'
  post 'clinic/todays_registration'

  get 'clinic/this_months_registration'
  post 'clinic/this_months_registration'

  get 'clinic/this_years_registration'
  post 'clinic/this_years_registration'


  get '/new_location' => 'clinic#new_location'
  get '/delete_location' => 'clinic#delete_location'
  get '/print_location' => 'clinic#print_location'

  post 'location/create'
  post 'location/print'
  post 'location/delete'
  get 'location/search'
  get 'location/location_label'

  get 'report' => 'report#report'
  get 'registration_report_menu' => 'report#registration_report_menu'
  post 'registration_report' => 'report#registration_report'

  get 'quartely_report_menu' => 'report#quartely_report_menu'
  get 'quartely_report' => 'report#quartely_report'
  post 'quartely_report' => 'report#quartely_report'
  post 'get_quartely_report_data' => 'report#get_quartely_report_data' #get_hiv_data

  get 'get_hiv_data' => 'report#get_hiv_data'
  post 'get_hiv_data' => 'report#get_hiv_data'

  get 'get_circumcision_status_data' => 'report#get_circumcision_status_data'
  post 'get_circumcision_status_data' => 'report#get_circumcision_status_data'

  get 'get_contraindications_data' => 'report#get_contraindications_data'
  post 'get_contraindications_data' => 'report#get_contraindications_data' #get_consent_granted_data

  get 'get_consent_granted_data' => 'report#get_consent_granted_data'
  post 'get_consent_granted_data' => 'report#get_consent_granted_data' #get_procedures_used_data

  get 'get_procedures_used_data' => 'report#get_procedures_used_data'
  post 'get_procedures_used_data' => 'report#get_procedures_used_data' #get_adverse_events_data

  get 'get_adverse_events_data' => 'report#get_adverse_events_data'
  post 'get_adverse_events_data' => 'report#get_adverse_events_data'

  get 'user' => 'clinic#user'
  get 'manage_locations' => 'clinic#manage_locations'
  get 'manage_villages' => 'clinic#manage_villages'
  get '/work_station' => 'clinic#work_station'
  post '/work_station' => 'clinic#work_station'
  get '/header' => 'patients#header'
  get '/encounters/new' => 'encounters#new'
  get '/vitals' => 'encounters#vitals'
  get '/medical_history' => 'encounters#medical_history'
  get '/hiv_art_status' => 'encounters#hiv_art_status'
  get '/genital_examination' => 'encounters#genital_examination'
  get '/summary_assessment' => 'encounters#summary_assessment'
  get '/circumcision' => 'encounters#circumcision'
  get '/post_op_review' => 'encounters#post_op_review'
  get '/registration' => 'encounters#registration'
  get '/follow_up_review' => 'encounters#follow_up_review'
  get '/person_names/given_names' => 'person_names#given_names'
  get '/person_names/family_names' => 'person_names#family_names'
  get '/person_names/middle_name' => 'person_names#middle_name'

  post '/encounters/create'
  post '/patients/get_patient_visits'
  post '/patients/get_patient_vitals'
  get '/patients/get_patient_vitals'

  get '/patients/get_registration_encounter_status'
  post '/patients/get_registration_encounter_status'

  get '/patients/patient_is_circumcised'
  post '/patients/patient_is_circumcised'

  get '/patients/patient_is_circumcised_today'
  post '/patients/patient_is_circumcised_today'

  get '/patients/patient_consent_given'
  post '/patients/patient_consent_given'

  get '/patients/patient_circumcision_consent'
  post '/patients/patient_circumcision_consent'

  get '/patients/get_follow_up_status'
  post '/patients/get_follow_up_status'

  get '/patients/check_if_encounter_exists_on_date'
  post '/patients/check_if_encounter_exists_on_date'

  get '/patients/get_next_task'
  post '/patients/get_next_task'

  get '/patients/update_demographics'
  post '/patients/update_demographics'

  get '/encounters/details'
  post '/encounters/observations'
  get '/encounters/observations'
  post '/encounters/void'

  #user settings route
  get "/users" => "users#user"
  get "user/change_password" => "users#change_password"
  post "/change_password" => "users#change_password"
  get '/administration' => 'users#administration' #edit_user
  post '/update_role' => "users#update_role"
  get 'user/change_role' => 'users#change_role'
  get 'user/edit/:id' => 'users#edit_user'
  post '/edit_user' => 'users#update'
  get "/new_user" => "users#new_user"
  post "/new_user" => "users#new_user"
  get "/view_users" => "users#view_users"
  post "/view_users" => "users#view_users"
  get "/users/role"
  get "/users/username"
  get "/show/:id" => "users#show"

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
