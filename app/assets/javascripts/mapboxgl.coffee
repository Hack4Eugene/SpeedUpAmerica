popup = null
paint_options = {
  'fill-antialias': true,
  'fill-outline-color': '#000000',
  'fill-color':['get', 'color'],
  'fill-opacity': ['get', 'fillOpacity']
}
census_layer_name = 'census-tracts' 
zip_layer_name = 'zip-codes'

window.initialize_mapboxgl = (elmID) ->
  mapboxgl.accessToken = MAPBOX_API_KEY;
  maxZoom = 14

  map = new mapboxgl.Map({
    container: elmID,
    style: 'mapbox://styles/mapbox/streets-v9'
    center: [-120.67382, 44.0639066],
    zoom: 6,
    maxZoom: maxZoom
  })


  # disable map rotation using right click + drag
  map.dragRotate.disable();

  # disable map rotation using touch rotation gesture
  map.touchZoomRotate.disableRotation();  

  # Add zoom and rotation controls to the map.
  map.addControl(new mapboxgl.NavigationControl({showCompass: false}))

  $('.leaflet-bottom').addClass('hide')

  map

get_map_loader = (map) ->
  map_id = map.getContainer().id

  if map_id == 'all_results_map'
    loader_id = '#loader'
  else if map_id == 'zip_code_map'
    loader_id = '#stats_loader'

  $(loader_id)
  
clearMap = (map) ->
  if popup 
    popup.remove()

  for name in [census_layer_name, zip_layer_name]
    if map.getLayer(name)
      map.removeLayer(name)
    if map.getSource(name)
      map.removeSource(name)

addLayer = (map, name, data, test_type, layer_type) -> 
  map.addLayer({
    'id': name,
    'type': 'fill',
    'source': {
      'type': 'geojson',
      'data':  {
          'type': 'FeatureCollection',
          'features': data
      },
    },
    'paint': paint_options    
  });

  map.on('mouseenter', name, () -> 
    map.getCanvas().style.cursor = 'pointer';
  )

  map.on('mouseleave', name,  () -> 
    map.getCanvas().style.cursor = '';
  )

  map.on('click', name, (e) ->
    feature = e.features[0]

    content = "<h5>Test Results for #{layer_type}: " + feature.properties.title + "</h5>" +
      "<p>Tests in this #{layer_type}: <strong>" + feature.properties.count + '</strong></p><br />' +
      "<p>Median #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" +
        feature.properties.median_speed + " Mbps</strong></p>" +
      "<p>Fastest #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" +
        feature.properties.fast_speed + " Mbps</strong></p>"
    
    if popup 
      popup.remove()

    popup = new mapboxgl.Popup()
      .setLngLat(e.lngLat)
      .setHTML(content)
      .addTo(map)
  )

getData = () ->
  

window.set_mapbox_zip_data_gl = (map, provider, date_range, group_by='zip_code', test_type='download') ->
  loader = get_map_loader(map)
  loader.removeClass('hide')

  clearMap(map)

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
      addLayer(map, zip_layer_name, data, test_type, "Zip Code")

      loader.addClass('hide')
      disable_filters('map-filters', false)
    error: (request, status, error) ->
      throw new Error("get zip data failed: " + request.status  + " " +
        request.responseText + " " + error)

window.set_mapbox_census_data_gl = (map, provider, date_range, test_type, zip_code, census_code, type) ->
  loader = get_map_loader(map)
  loader.removeClass('hide')

  clearMap(map)

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
      addLayer(map, census_layer_name, data, test_type, 'Census Tracts')

      loader.addClass('hide')
      disable_filters('map-filters', false)
    error: (request, status, error) ->
      throw new Error("get census data failed: " + request.status  + " " +
        request.responseText + " " + error)

