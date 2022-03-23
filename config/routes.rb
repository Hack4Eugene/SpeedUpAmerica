Rails.application.routes.draw do

  resources :home, only: :index do
    collection do
      post :calculate_ping
    end
  end

  resources :submissions, only: :create do
    collection do
      post :export_csv, defaults: { format: :csv }
    end
  end

  get 'all-results', to: 'submissions#result_page', as: :result_page
  get 'region-results', to: 'regionsubmissions#result_page', as: :regionresult_page
  get 'result/:test_id', to: 'submissions#show', as: :submission
  get 'regionresult/:test_id', to: 'regionsubmissions#show', as: :regionsubmission
  post 'stats/groupby', to: 'submissions#tileset_groupby', defaults: { format: :json }
  get 'speed_data', to: 'submissions#speed_data'
  get 'internet-stats', to: redirect('all-results')
  get 'embeddable_view', to: 'submissions#embeddable_view'
  get 'embed', to: 'submissions#embed', defaults: { format: :js }, constraints: { format: :js }
  get 'region/*regionname', to: 'region#index'
  get '/:page', to: 'static#show'
  root 'home#index'

  #match '*invalid_path', to: errors#not_found

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

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
