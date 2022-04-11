module RegionHelper
  def region_provider_list(form_type = {first_step: true})
    ProviderStatistic.pluck(:name)
  end

end
