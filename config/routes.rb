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

  resources :region_submissions, only: :create do
    collection do
      post :region_export_csv, defaults: { format: :csv }
      get :region_export_csv_report, defaults: { format: :csv }
    end
  end


  class RestrictedRegionListConstraint
    def matches?(request)
      request[:regionname] =~ /\ball\b|\boregon\b|\bOregon\b|\boregon-es\b|\bOregon-es\b|\bwashington\b|\bWashington\b|\bwashington-es\b|\bWashington-es\b|\bcalifornia\b|\bCalifornia\b|\bcalifornia-es\b|\bCalifornia-es\b/
    end
  end


  # SpeedUpAmerica routes
  get 'all-results', to: 'submissions#result_page', as: :result_page
  get 'result/:test_id', to: 'submissions#show', as: :submission
  post 'stats/groupby', to: 'submissions#tileset_groupby', defaults: { format: :json }
  get 'speed_data', to: 'submissions#speed_data'
  get 'internet-stats', to: redirect('all-results')
  get 'embeddable_view', to: 'submissions#embeddable_view'
  get 'embed', to: 'submissions#embed', defaults: { format: :js }, constraints: { format: :js }

  # region routes
  get 'region-results/*regionname', to: 'region_submissions#result_page', as: :region_result_page, constraints: RestrictedRegionListConstraint.new
  get 'region-result/:test_id', to: 'region_submissions#show', as: :region_submission
  post 'region-stats/groupby/*regionname', to: 'region_submissions#tileset_groupby', defaults: { format: :json }, constraints: RestrictedRegionListConstraint.new
  get 'region_speed_data/*regionname', to: 'region_submissions#speed_data', constraints: RestrictedRegionListConstraint.new
  get 'region_internet-stats/*regionname', to: redirect('region-all-results'), constraints: RestrictedRegionListConstraint.new
  get 'region-embed/*regionname', to: 'region_submissions#embed', defaults: { format: :js }, constraints: { format: :js }
  get 'region/*regionname', to: 'region#index', defaults: {
	regionname: 'Oregon' }, constraints: RestrictedRegionListConstraint.new

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

