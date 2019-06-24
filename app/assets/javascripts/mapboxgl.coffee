popup = null
census_layer = {
  url: 'mapbox://mattsayre.29aqw5xm',
  source: 'census-tracts',
  name: 'tracts',
  data_id: 'GEOID'
}
zip_layer = {
  url: 'mapbox://mattsayre.857dv4qz',
  source: 'zip-codes',
  name: 'cb_2018_us_zcta510_500k',
  data_id: 'ZCTA5CE10'
}

window.initialize_mapboxgl = (elmID) ->
  mapboxgl.accessToken = MAPBOX_API_KEY;
  maxZoom = 14

  map = new mapboxgl.Map({
    container: elmID,
    style: 'mapbox://styles/mapbox/streets-v9',
    center: [-117.879376, 45.392022],
    zoom: 5,
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

  for layer in [census_layer, zip_layer]
    if map.getLayer(layer.name)
      map.removeLayer(layer.name)
    if map.getSource(layer.source)
      map.removeSource(layer.source)

addLayer = (map, layer, data, test_type, layer_type) -> 
  map.addSource(layer.source, {
    type: "vector",
    url: layer.url
  });

  colorExpression = ["match", ["get", layer.data_id]]
  opacityExpression = ["match", ["get", layer.data_id]]
  lineExpression = ["match", ["get", layer.data_id]]
  # Calculate color for each state based on the unemployment rate
  data.forEach((row) ->
    colorExpression.push(row["id"], row["color"])
    opacityExpression.push(row["id"], row["fillOpacity"])
    lineExpression.push(row["id"], "#000000")
  )  
  # Last value is the default, used where there is no data
  colorExpression.push("rgba(0, 0, 0, 0)");
  opacityExpression.push(0.0)
  lineExpression.push("rgba(0, 0, 0, 0)");

  
  # Add layer from the vector tile source with data-driven style
  map.addLayer({
    "id": layer.name,
    "type": "fill",
    "source": layer.source,
    "source-layer": layer.name,
    "paint": {
      'fill-antialias': true,
      'fill-outline-color': lineExpression,
      'fill-color': colorExpression,
      'fill-opacity': opacityExpression
    }
  })

  map.on('mouseenter',  layer.name, () -> 
    map.getCanvas().style.cursor = 'pointer';
  )

  map.on('mouseleave', layer.name,  () -> 
    map.getCanvas().style.cursor = '';
  )

  map.on('click',  layer.name, (e) ->
    feature = e.features[0]
    id = feature.properties[layer.data_id]
    stats = {
        id: "Unknown"
        all_median: 0,
        all_count: 0,
        all_fast: 0
    }

    for datum in data
      if datum["id"] == id
        stats = datum
        break

    content = "<h4>#{layer_type}: " + stats.id + "</h4>" +
      "<p>Tests in this #{layer_type}: <strong>" + stats.all_count + '</strong></p>' +
      "<p>Median #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" +
        stats.all_median + " Mbps</strong></p>" +
      "<p>Fastest #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" +
        stats.all_fast + " Mbps</strong></p>"
    
    if popup 
      popup.remove()

    popup = new mapboxgl.Popup()
      .setLngLat(e.lngLat)
      .setHTML(content)
      .addTo(map)
  )  

window.set_mapbox_zip_data_gl = (map, provider, date_range, group_by='zip_code', test_type='download') ->
  loader = get_map_loader(map)
  loader.removeClass('hide')

  clearMap(map)

  $.ajax
    url: '/stats/groupby'
    type: 'POST'
    dataType: 'json'
    data:
      provider: provider
      date_range: date_range
      group_by: group_by
      test_type: test_type
    success: (data) ->
      addLayer(map, zip_layer, data.result, test_type, "Zip Code")

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
    url: '/stats/groupby'
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
      addLayer(map, census_layer, data.result, test_type, 'Census Tract')

      loader.addClass('hide')
      disable_filters('map-filters', false)
    error: (request, status, error) ->
      throw new Error("get census data failed: " + request.status  + " " +
        request.responseText + " " + error)

