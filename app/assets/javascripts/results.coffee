$ ->
  if window.location.pathname.indexOf('result') >= 0
    # Initialize filter values
    bind_chosen_select()
    set_multiple_selected_values()

    # Create results
    all_results_map = initialize_mapboxgl('all_results_map')
    all_results_map.on('load', () ->
      # Draw polygons on the map
      apply_filters(all_results_map)
      # Add functionality to UI
      apply_submission_filters()
    )
    
    # Create stats map
    $("#selected_zip_code").val(ZIP_CODE)
    apply_stats_filters()
    $('#stats_filters #stats_test_type').change()
        

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

monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "June",
  "July", "Aug", "Sep", "Oct", "Nov", "Dec"
];
 
apply_filters = (map) ->
  update_map = ->
    provider = $('#provider').val()
    group_by = $('#group_by').val()
    test_type = $('#test_type').val()
    
    update_csv_link()
    disable_filters('map-filters', true)

    $('#all_results_map').removeClass('hide')

    if group_by == 'zip_code'
      set_mapbox_zip_data_gl(map, provider, group_by, test_type)
    else if group_by == 'census_code'
      set_mapbox_census_data_gl(map, provider, test_type, '', '', '')
  
  $('#map-filters .filter').on 'change', ->
    update_all_option($(this))
    update_map()
  
  update_map()

apply_submission_filters = ->
  if $('#connecion_type').attr('value')
    $('.connection-type-buttons button').each ->
      $(this).removeClass().addClass('btn btn-default')

    active_button = $('.connection-type-buttons').find("button[data-value='" + $('#connecion_type').attr('value') + "']")
    active_button.removeClass().addClass('btn btn-primary')


apply_stats_filters = ->
  $('#stats_filters .filter').on 'change', ->
    update_all_option($(this))
    $('.stats-section').addClass('blurred')
    $('#stats_loader').removeClass('hide')
    filter = $(this).attr('id')
    statistics = get_stats_filters()
    disable_filters('stats_filters', true)

    update_statistics(statistics, filter)


get_stats_filters = ->
  {
    'provider': $('#stats_provider').val()
    'test_type': $('#stats_test_type').val()
    'zip_code': $('#zip_code').val()
    'census_code': $('#census_code').val()
  }

update_statistics = (statistics, filter) ->
  draw_stats_charts(statistics, filter)

window.disable_filters = (container, disabled) ->
  filters = $("##{container} .filter")
  filters.attr('disabled', disabled).trigger('chosen:updated')

update_csv_link = (date_range) ->
  root_url = $('#root_url').val()
  $('.export-btn').prop('href', "#{root_url}submissions/export_csv")

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