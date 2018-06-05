initialize_mapbox = (map) ->
  L.mapbox.accessToken = 'pk.eyJ1IjoiY29udGVudHRvb2xzIiwiYSI6ImRjNzE0OTlkYjk2NGJkZWEwMTZmY2QwMTJlYjdjMGI1In0.qKp5IAUQySQHQoT8JBd3ew'

  map = L.mapbox.map(map, 'mapbox.light', { maxZoom: 13 }).setView([
     37.3169326,
    -121.8778367
  ], 11)

  map.scrollWheelZoom.disable();

  map.on 'click', (e) ->
    map.scrollWheelZoom.enable();

  $('.leaflet-bottom').addClass('hide')

  map

set_mapbox_polygon_data = (map, group_by='zip_code', connection_type='Home Wifi', satisfaction='All') ->
  $('#loader').removeClass('hide')

  $.ajax
    url: '/mapbox_data'
    type: 'POST'
    dataType: 'json'
    data:
      group_by: group_by
      connection_type: connection_type
      satisfaction: satisfaction
    success: (data) ->
      $('.selected-zipcode-section').addClass('hidden')
      $('.group-by-buttons button[data-value=all_responses]').addClass('hidden')
      map.eachLayer (layer) ->
        map.removeLayer layer

      map.addLayer L.mapbox.tileLayer('mapbox.light')

      L.geoJson(data,
        pointToLayer: L.mapbox.marker.style,
        style: (feature) ->
          feature.properties
        onEachFeature: (feature, layer) ->
          link = "/change_zipcode?zipcode=#{feature.properties.title}"
          content = '<h2>Test Results for ' + feature.properties.title + ':</h2>' +
                    '<p>Tests in this zip code: <strong>(' + feature.properties.count + ')</strong></p><br />' +
                    '<p>Median Download Speed: <strong>' + feature.properties.median_speed + ' Mbps</strong></p>' +
                    '<p>Fastest Download Speed: <strong>' + feature.properties.fast_speed + ' Mbps</strong></p>' +
                    "<a href=#{link} class='all-responses-link' data-remote=true>See All Responses</a>"
          layer.bindPopup content, closeButton: false
      ).addTo map

      $('#loader').addClass('hide')

set_internet_stats_mapbox = (map, group_by='zip_code', satisfaction='All') ->
  connection_type = ['Home Wifi', 'Mobile Data', 'Public Wifi']

  $.ajax
    url: '/mapbox_data'
    type: 'POST'
    dataType: 'json'
    data:
      type: 'stats'
      group_by: group_by
      connection_type: connection_type
      satisfaction: satisfaction
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
          content = '<p>Tests in this zip code: <strong>(' + feature.properties.count + ')</strong></p>'
          layer.bindPopup content, closeButton: false
          myIcon = L.divIcon(className: 'my-div-icon', html: '<strong>' + feature.properties.count + '</strong>')
          L.marker([parseFloat(center.lng), parseFloat(center.lat)], {icon: myIcon}).addTo(map)
      ).addTo map

set_mapbox_markers_data = (map, group_by='all_responses', connection_type='Home Wifi', satisfaction='All', zipcode='95132') ->
  $('#loader').removeClass('hide')

  $.ajax
    url: '/mapbox_data'
    type: 'POST'
    dataType: 'json'
    data:
      group_by: group_by
      connection_type: connection_type
      satisfaction: satisfaction
      zipcode: zipcode
    success: (data) ->
      $('.selected-zipcode-section').removeClass('hidden')
      map.eachLayer (layer) ->
        map.removeLayer layer

      map.addLayer L.mapbox.tileLayer('mapbox.light')

      L.geoJson(data,
        pointToLayer: L.mapbox.marker.style,
        style: (feature) ->
          feature.properties
        onEachFeature: (feature, layer) ->
          content = '<p>Download Speed: <strong>' + feature.properties.title + ' Mbps</strong></p>' +
                    '<p>Connection Type: <strong>' + feature.properties.connection_type + '</strong></p>' +
                    '<p>Satisfaction: <strong>' + feature.properties.satisfaction + '</strong></p>'
          layer.bindPopup content, closeButton: false
      ).addTo map

      $('#loader').addClass('hide')

apply_filters = (map) ->
  $('.connection-type-buttons, .group-by-buttons, .satisfaction-buttons').on 'click', (e) ->
    $(this).find('button').each ->
      $(this).removeClass().addClass('btn btn-default')
      $(e.target).removeClass('btn-default').addClass('btn-primary')

    active_buttons = $('#map-filters').find('button.btn-primary')
    connection_type = active_buttons.first().data('value')
    satisfaction = active_buttons.last().text()
    group_by = active_buttons.eq(1).data('value')

    if group_by == 'zip_code'
      set_mapbox_polygon_data(map, group_by, connection_type, satisfaction)
    else
      zipcode = $('#selected_zipcode').val()
      set_mapbox_markers_data(map, group_by, connection_type, satisfaction, zipcode)

apply_submission_filters = ->
  if $('#connecion_type').attr('value')
    $('.connection-type-buttons button').each ->
      $(this).removeClass().addClass('btn btn-default')

    active_button = $('.connection-type-buttons').find("button[data-value='" + $('#connecion_type').attr('value') + "']")
    active_button.removeClass().addClass('btn btn-primary')

is_internet_stats_page = ->
  window.location.pathname.indexOf('internet-stats') >= 0

$(document).ready ->
  if window.location.pathname.indexOf('result') >= 0
    all_results_map = initialize_mapbox('all_results_map')
    zip_code_map = initialize_mapbox('zip_code_map')
    set_internet_stats_mapbox(zip_code_map)
    apply_submission_filters()
    set_mapbox_polygon_data(all_results_map, 'zip_code', $('#connecion_type').attr('value'))
    apply_filters(all_results_map)
