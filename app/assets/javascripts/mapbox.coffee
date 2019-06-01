jQuery.loadScript = (url, callback) ->
  jQuery.ajax
    url: url
    dataType: 'script'
    success: callback
    async: true

isIE = ->
  ua = window.navigator.userAgent
  msie = ua.indexOf('MSIE ')
  if msie > 0
    # IE 10 or older => return version number
    return parseInt(ua.substring(msie + 5, ua.indexOf('.', msie)), 10)
  trident = ua.indexOf('Trident/')
  if trident > 0
    # IE 11 => return version number
    rv = ua.indexOf('rv:')
    return parseInt(ua.substring(rv + 3, ua.indexOf('.', rv)), 10)
  edge = ua.indexOf('Edge/')
  if edge > 0
    # Edge (IE 12+) => return version number
    return parseInt(ua.substring(edge + 5, ua.indexOf('.', edge)), 10)
  # other browser
  false

initialize_mapbox = (map) ->
  L.mapbox.accessToken = 'pk.eyJ1IjoiY29udGVudHRvb2xzIiwiYSI6ImRjNzE0OTlkYjk2NGJkZWEwMTZmY2QwMTJlYjdjMGI1In0.qKp5IAUQySQHQoT8JBd3ew'
  maxZoom = isIE() && 12 || 14

  map = L.mapbox.map(map, 'mapbox.light', { maxZoom: maxZoom }).setView([44.0639066, -120.67382], 7)

  map.scrollWheelZoom.disable();

  map.on 'click', (e) ->
    map.scrollWheelZoom.enable();

  $('.leaflet-bottom').addClass('hide')

  map

set_mapbox_polygon_data = (map, provider, date_range, group_by='zip_code', test_type='download') ->
  $('#loader').removeClass('hide')
  $.ajax
    url: '/mapbox_data'
    type: 'POST'
    dataType: 'json'
    data:
      provider: provider
      date_range: date_range
      group_by: group_by
      test_type: test_type
    success: (data) ->
      map.eachLayer (layer) ->
        map.removeLayer layer

      map.addLayer L.mapbox.tileLayer('mapbox.light')

      L.geoJson(data,
        style: (feature) ->
          feature.properties
        onEachFeature: (feature, layer) ->
          polygon = new (L.Polygon)(feature.geometry.coordinates[0]).addTo(map)
          bounds = polygon.getBounds()
          center = bounds.getCenter()
          content = '<h2>Test Results for ' + feature.properties.title + ':</h2>' +
                    '<p>Tests in this zip code: <strong>(' + feature.properties.count + ')</strong></p><br />' +
                    '<p>Median Speed: <strong>' + feature.properties.median_speed + ' Mbps</strong></p>' +
                    '<p>Fastest Speed: <strong>' + feature.properties.fast_speed + ' Mbps</strong></p>'
          layer.bindPopup content, closeButton: false
      ).addTo map

      $('#loader').addClass('hide')
      disable_filters('map-filters', false)

set_mapbox_census_data = (map, provider, date_range, test_type, zip_code, census_code, type) ->
  $('#loader').removeClass('hide')
  $.ajax
    url: '/mapbox_data'
    type: 'POST'
    dataType: 'json'
    data:
      provider: provider
      date_range: date_range
      group_by: 'census_code'
      test_type: test_type
      zip_code: zip_code
      census_code: census_code
      type: type
    success: (data) ->
      map.eachLayer (layer) ->
        map.removeLayer layer

      map.addLayer L.mapbox.tileLayer('mapbox.light')

      L.geoJson(data,
        style: (feature) ->
          feature.properties
        onEachFeature: (feature, layer) ->
          polygon = new (L.Polygon)(feature.geometry.coordinates[0]).addTo(map)
          bounds = polygon.getBounds()
          center = bounds.getCenter()
          content = "<p>Tests in census block #{feature.properties.title}: <strong>(#{feature.properties.count})</strong></p>" +
                    '<p>Median Speed: <strong>' + feature.properties.median_speed + ' Mbps</strong></p>' +
                    '<p>Fastest Speed: <strong>' + feature.properties.fast_speed + ' Mbps</strong></p>'
          layer.bindPopup content, closeButton: false
      ).addTo map

      $('#loader').addClass('hide')
      disable_filters('map-filters', false)

set_mapbox_markers_data = (map, provider, date_range, group_by='all_responses', test_type='download') ->
  $('#loader').removeClass('hide')
  $('#mapbox_gl_map').addClass('hide')
  $('#all_results_map').removeClass('hide')

  $.ajax
    url: '/mapbox_data'
    type: 'POST'
    dataType: 'json'
    data:
      provider: provider
      date_range: date_range
      group_by: group_by
      test_type: test_type
      is_ie: 'yes'
    success: (data) ->
      map.eachLayer (layer) ->
        map.removeLayer layer

      map.addLayer L.mapbox.tileLayer('mapbox.light')

      markers = new (L.MarkerClusterGroup)(
        spiderfyOnMaxZoom: false
        showCoverageOnHover: true
        zoomToBoundsOnClick: true)

      i = 0
      while i < data.length
        feature = data[i]
        title = feature.title
        marker = L.marker(new (L.LatLng)(feature.geometry.latitude, feature.geometry.longitude),
          icon: L.mapbox.marker.icon(feature.properties)
          title: title)
        marker.bindPopup title, closeButton: false
        markers.addLayer marker
        i++

      map.addLayer markers

      $('#loader').addClass('hide')
      disable_filters('map-filters', false)

set_mapbox_gl_data = (map, provider, date_range, group_by='all_responses', test_type='download') ->
  $('#loader').removeClass('hide')
  $('#mapbox_gl_map').removeClass('hide')
  $('#all_results_map').addClass('hide')

  $.ajax
    url: '/mapbox_data'
    type: 'POST'
    dataType: 'json'
    data:
      provider: provider
      date_range: date_range
      group_by: group_by
      test_type: test_type
      is_ie: 'no'
    success: (data) ->
      mapboxgl.accessToken = 'pk.eyJ1IjoiY29udGVudHRvb2xzIiwiYSI6ImRjNzE0OTlkYjk2NGJkZWEwMTZmY2QwMTJlYjdjMGI1In0.qKp5IAUQySQHQoT8JBd3ew'
      map = new (mapboxgl.Map)(
        container: 'mapbox_gl_map'
        style: 'mapbox://styles/mapbox/light-v9'
        center: [
          -85.6728608
          38.2277224
        ]
        zoom: 10)
      map.on 'load', ->
        map.addSource 'speed_tests',
          type: 'geojson'
          data: data
          cluster: true
          clusterMaxZoom: 15
          clusterRadius: 50

        map.addLayer
          'id': 'unclustered-points'
          'type': 'symbol'
          'source': 'speed_tests'
          'filter': [
            '!has'
            'point_count'
          ]
          'layout': 'icon-image': 'marker-15'

        layers = [
          [600, '#8EB4E3']
          [300, '#8EB4E3']
          [150, '#8EB4E3']
          [20, '#8EB4E3']
          [0, '#8EB4E3']
        ]

        layers.forEach (layer, i) ->
          map.addLayer
            'id': 'cluster-' + i
            'type': 'circle'
            'source': 'speed_tests'
            'paint':
              'circle-color': layer[1]
              'circle-radius': 18
            'filter': if i == 0 then [
              '>='
              'point_count'
              layer[0]
            ] else [
              'all'
              [
                '>='
                'point_count'
                layer[0]
              ]
              [
                '<'
                'point_count'
                layers[i - 1][0]
              ]
            ]

        map.addLayer
          'id': 'cluster-count'
          'type': 'symbol'
          'source': 'speed_tests'
          'layout':
            'text-field': '{point_count}'
            'text-font': [
              'DIN Offc Pro Medium'
              'Arial Unicode MS Bold'
            ]
            'text-size': 12

      map.on 'click', (e) ->
        features = map.queryRenderedFeatures(e.point, layers: [ 'unclustered-points' ])
        if !features.length
          return
        feature = features[0]
        popup = (new (mapboxgl.Popup)).setLngLat(feature.geometry.coordinates).setHTML(feature.properties.description).addTo(map)

      map.on 'mousemove', (e) ->
        features = map.queryRenderedFeatures(e.point, layers: [ 'unclustered-points' ])
        map.getCanvas().style.cursor = if features.length then 'pointer' else ''

      setTimeout (->
        $('#loader').addClass('hide')
        $('.mapboxgl-ctrl-attrib').addClass('hidden')
        disable_filters('map-filters', false)
      ), 1200

speed_breakdown_by_isp_chart = (data) ->
  $('#speed_breakdown_by_isp').highcharts
    chart: type: 'areaspline'
    legend:
      align: 'center'
      verticalAlign: 'top'
      layout: 'horizontal'
    title: text: ''
    xAxis:
      categories: data.categories
      title: text: null
    yAxis:
      min: 0
      title:
        text: ''
        align: 'high'
      labels:
        enabled: true
        overflow: 'justify'
        formatter: ->
          @value + " %"
    tooltip: valueSuffix: " %"
    colors: ['#FF00FF', '#9A7A53', '#D7A069', '#526D7A', '#8CABEC', '#FF3232', '#0A6F42']
    plotOptions: bar:
      dataLabels: enabled: true
      column: colorByPoint: true
    credits: enabled: false
    series: data.series

median_speed_by_isp_chart = (data) ->
  $('#median_speed_by_isp_chart').highcharts
    chart: type: 'spline'
    credits: enabled: false
    title: text: ''
    legend:
      align: 'center'
      verticalAlign: 'top'
      layout: 'horizontal'
    xAxis: categories: data.categories
    yAxis:
      title: text: 'Internet Speed (Mbps)'
    colors: ['#FF00FF', '#9A7A53', '#D7A069', '#526D7A', '#8CABEC', '#FF3232', '#0A6F42']
    plotOptions: line:
      dataLabels: enabled: false
      enableMouseTracking: false
      column: colorByPoint: true
    series: data.series

tests_per_isp_chart = (data) ->
  $('#tests_per_isp_chart').highcharts
    chart: events: load: ->
      $('.stats-section').removeClass('blurred')
      $('#stats_loader').addClass('hidden')
    type: 'column'
    credits: enabled: false
    title: text: ''
    xAxis: categories: data.categories
    yAxis:
      min: 0
      title: text: 'Number of Tests'
      stackLabels:
        enabled: false
    legend:
      align: 'center'
      verticalAlign: 'top'
      layout: 'horizontal'
    colors: ['#FF00FF', '#9A7A53', '#D7A069', '#526D7A', '#8CABEC', '#FF3232', '#0A6F42']
    plotOptions: column:
      stacking: 'normal'
      dataLabels:
        enabled: false
      column: colorByPoint: true
    series: data.series

draw_stats_charts = (statistics, filter) ->
  disable_filters('stats_filters', true)
  $.ajax
    url: '/speed_data'
    type: 'GET'
    dataType: 'json'
    data:
      statistics: statistics
    success: (data) ->
      if Object.keys(data).length > 0
        bind_home_speed_comparison_values(data.speed_comparison_data)
        speed_breakdown_by_isp_chart(data.speed_breakdown_chart_data)
        median_speed_by_isp_chart(data.median_speed_chart_data)
        tests_per_isp_chart(data.tests_count_data)
        $('.total-tests').text(data.total_tests)
        disable_filters('stats_filters', false)
      else
        $('.stats-section').removeClass('blurred')
        $('#stats_loader').addClass('hidden')
        disable_filters('stats_filters', true) 

average = (data) ->
  data.reduce(((p, c, i, a) ->
    p + c / a.length
  ), 0)

bind_home_speed_comparison_values = (values) ->
  $('.home-speed-0-to-5').text("#{values.less_than_5.toFixed(2)}%")
  $('.home-speed-6-to-25').text("#{values.less_than_25.toFixed(2)}%")
  $('.home-speed-101-to-200').text("#{values.faster_than_100.toFixed(2)}%")
  $('.home-speed-201-to-500').text("#{values.faster_than_250.toFixed(2)}%")
  $('.speedup-tests-count').text(values.speedup_tests_count)
  $('.mlab-tests-count').text(values.mlab_tests_count)

update_statistics = (map, statistics, filter) ->
  set_mapbox_census_data(map, statistics.provider, statistics.date_range, statistics.test_type, statistics.zip_code, statistics.census_code, 'stats')
  draw_stats_charts(statistics, filter)

disable_filters = (container, disabled) ->
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

set_multiple_selected_values = ->
  $.each ['provider', 'stats_provider', 'zip_code', 'census_code'], (index, id) ->
    $("#selected_#{id}").val($("##{id}").val())

apply_filters = (map) ->
  update_map = ->
    provider = $('#provider').val()
    group_by = $('#group_by').val()
    test_type = $('#test_type').val()
    date_range = [$('#start_date').val(), $('#end_date').val()].join(' - ')
    update_csv_link(date_range)
    disable_filters('map-filters', true)

    $('#mapbox_gl_map').addClass('hide')
    $('#all_results_map').removeClass('hide')

    if group_by == 'zip_code'
      set_mapbox_polygon_data(map, provider, date_range, group_by, test_type)
    else if group_by == 'census_code'
      set_mapbox_census_data(map, provider, date_range, test_type, '', '', '')
    else if group_by == 'all_responses' && !isIE()
      set_mapbox_gl_data(map, provider, date_range, group_by, test_type)
    else if group_by == 'all_responses' && isIE()
      set_mapbox_markers_data(map, provider, date_range, group_by, test_type)

  $('#map-filters .filter').on 'change', ->
    set_date_filters_value($(this)) if $(this).val() == ''
    update_all_option($(this))
    update_map()

  update_map()

get_stats_filters = ->
  {
    'date_range': [$('#stats_start_date').val(), $('#stats_end_date').val()].join(' - ')
    'provider': $('#stats_provider').val()
    'test_type': $('#stats_test_type').val()
    'period': $('#period').val()
    'zip_code': $('#zip_code').val()
    'census_code': $('#census_code').val()
  }

apply_stats_filters = (map) ->
  $('#stats_filters .filter').on 'change', ->
    update_all_option($(this))
    set_date_filters_value($(this)) if $(this).val() == ''
    $('.stats-section').addClass('blurred')
    $('#stats_loader').removeClass('hidden')
    filter = $(this).attr('id')
    statistics = get_stats_filters()
    disable_filters('stats_filters', true)

    update_statistics(map, statistics, filter)

apply_submission_filters = ->
  if $('#connecion_type').attr('value')
    $('.connection-type-buttons button').each ->
      $(this).removeClass().addClass('btn btn-default')

    active_button = $('.connection-type-buttons').find("button[data-value='" + $('#connecion_type').attr('value') + "']")
    active_button.removeClass().addClass('btn btn-primary')

is_internet_stats_page = ->
  window.location.pathname.indexOf('internet-stats') >= 0

bind_chosen_select = ->
  $('.chosen-select').chosen
    no_results_text: 'No results matched'

  selected_ids = $('#stats_provider').data('selected-ids')
  $('#provider').val('all').trigger('chosen:updated')
  $('#stats_provider').val(selected_ids).trigger('chosen:updated')
  $('#period').val('Month').trigger('chosen:updated')
  $('#zip_code, #census_code').val('all').trigger('chosen:updated')

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

$(document).ready ->
  if window.location.pathname.indexOf('result') >= 0 || window.location.pathname.indexOf('embed') >= 0
    # Initialize filter values
    bind_chosen_select()
    set_multiple_selected_values()
    bind_datetimepicker()

    # Create maps
    all_results_map = initialize_mapbox('all_results_map')
    zip_code_map = initialize_mapbox('zip_code_map')

    # Draw polygons on the map
    apply_filters(all_results_map)

    # Add functionality to UI
    apply_submission_filters()

    $.loadScript 'https://code.highcharts.com/highcharts.js', ->
      apply_stats_filters(zip_code_map)
      $('#stats_filters #stats_start_date').change()
