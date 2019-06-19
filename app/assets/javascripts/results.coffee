$ ->
  if window.location.pathname.indexOf('result') >= 0
    # Initialize filter values
    bind_chosen_select()
    set_multiple_selected_values()
    bind_datetimepicker()

    # Create results
    # @MAP_SWITCH
    #all_results_map = initialize_mapbox('all_results_map')
    all_results_map = initialize_mapboxgl('all_results_map')

    # Draw polygons on the map
    apply_filters(all_results_map)

    # Add functionality to UI
    apply_submission_filters()
    
    # Create stats map
    if document.getElementById('zip_code_map') != null
      # @MAP_SWITCH
      #zip_code_map = initialize_mapbox('zip_code_map')
      zip_code_map = initialize_mapboxgl('zip_code_map')

      apply_stats_filters(zip_code_map)
      $('#stats_filters #stats_start_date').change()

bind_chosen_select = ->
  $('.chosen-select').chosen
    no_results_text: 'No results matched'

  selected_ids = $('#stats_provider').data('selected-ids')
  $('#provider').val('all').trigger('chosen:updated')
  $('#stats_provider').val(selected_ids).trigger('chosen:updated')
  $('#period').val('Month').trigger('chosen:updated')
  $('#zip_code, #census_code').val('all').trigger('chosen:updated')

set_multiple_selected_values = ->
  $.each ['provider', 'stats_provider', 'zip_code', 'census_code'], (index, id) ->
    $("#selected_#{id}").val($("##{id}").val())

bind_datetimepicker = ->
  $.each ['start_date', 'end_date', 'stats_start_date', 'stats_end_date'], (index, elem) ->
    set_date_filters_value($("##{elem}"))

  current_date = new Date()
  default_date = new Date()
  default_date.setFullYear(default_date.getFullYear() - 1)

  $('#start_date, #stats_start_date').datepicker
    format: 'MM dd, yyyy'
    endDate: current_date
    setDate: default_date
    autoclose: true

  $('#end_date, #stats_end_date').datepicker
    format: 'MM dd, yyyy'
    endDate: current_date
    setDate: default_date
    autoclose: true

apply_filters = (map) ->
  update_map = ->
    provider = $('#provider').val()
    group_by = $('#group_by').val()
    test_type = $('#test_type').val()
    date_range = [$('#start_date').val(), $('#end_date').val()].join(' - ')
    update_csv_link(date_range)
    disable_filters('map-filters', true)

    $('#all_results_map').removeClass('hide')

    if group_by == 'zip_code'
      # @MAP_SWITCH
      #set_mapbox_zip_data(map, provider, date_range, group_by, test_type)
      set_mapbox_zip_data_gl(map, provider, date_range, group_by, test_type)
    else if group_by == 'census_code'
      # @MAP_SWITCH
      #set_mapbox_census_data_(map, provider, date_range, test_type, '', '', '')
      set_mapbox_census_data_gl(map, provider, date_range, test_type, '', '', '')
  
  $('#map-filters .filter').on 'change', ->
    set_date_filters_value($(this)) if $(this).val() == ''
    update_all_option($(this))
    update_map()
  
  update_map()

apply_submission_filters = ->
  if $('#connecion_type').attr('value')
    $('.connection-type-buttons button').each ->
      $(this).removeClass().addClass('btn btn-default')

    active_button = $('.connection-type-buttons').find("button[data-value='" + $('#connecion_type').attr('value') + "']")
    active_button.removeClass().addClass('btn btn-primary')


apply_stats_filters = (map) ->
  $('#stats_filters .filter').on 'change', ->
    update_all_option($(this))
    set_date_filters_value($(this)) if $(this).val() == ''
    $('.stats-section').addClass('blurred')
    $('#stats_loader').removeClass('hide')
    filter = $(this).attr('id')
    statistics = get_stats_filters()
    disable_filters('stats_filters', true)

    update_statistics(map, statistics, filter)


get_stats_filters = ->
  {
    'date_range': [$('#stats_start_date').val(), $('#stats_end_date').val()].join(' - ')
    'provider': $('#stats_provider').val()
    'test_type': $('#stats_test_type').val()
    'period': $('#period').val()
    'zip_code': $('#zip_code').val()
    'census_code': $('#census_code').val()
  }

update_statistics = (map, statistics, filter) ->
  # @MAP_SWITCH
  #set_mapbox_census_data(map, statistics.provider, statistics.date_range, statistics.test_type, statistics.zip_code, statistics.census_code, 'stats')
  set_mapbox_census_data_gl(map, statistics.provider, statistics.date_range, statistics.test_type, statistics.zip_code, statistics.census_code, 'stats')
  draw_stats_charts(statistics, filter)

window.disable_filters = (container, disabled) ->
  filters = $("##{container} .filter")
  filters.attr('disabled', disabled).trigger('chosen:updated')

set_date_filters_value = (elem) ->
  date = new Date()
  month_names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']

  formatted_date = "#{month_names[date.getMonth()]} #{date.getDate()}, #{date.getFullYear()}"
  elem.val(formatted_date) if elem.prop('id') == 'end_date' || elem.prop('id') == 'stats_end_date'

  formatted_date = "#{month_names[date.getMonth()]} #{date.getDate()}, #{date.getFullYear() - 1}"
  elem.val(formatted_date) if elem.prop('id') == 'start_date' || elem.prop('id') == 'stats_start_date'

update_csv_link = (date_range) ->
  root_url = $('#root_url').val()
  $('.export-btn').prop('href', "#{root_url}submissions/export_csv?date_range=#{date_range}")

update_all_option = (elem) ->
  return if $.inArray(elem.prop('id'), ['provider', 'stats_provider', 'zip_code', 'census_code']) < 0
  selected_elem_value = $("#selected_#{elem.prop('id')}").val().split(',')

  new_selected = elem.val()

  if new_selected != null &&
    ($.inArray('all', selected_elem_value) != -1 ||
     $.inArray('all', new_selected) != -1)
    new_selected = elem.val().filter (v) -> v != 'all'

  if new_selected == null || new_selected.length == 0
      new_selected = 'all'

  elem.val(new_selected)
  $("#selected_#{elem.prop('id')}").val("#{[new_selected]}")