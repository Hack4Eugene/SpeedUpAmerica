popup = null

layers = {
  census_code: {
    url: 'mapbox://mattsayre.1pdu0bcw',
    source: 'census-tracts',
    name: 'tracts',
    data_id: 'GEOID',
    label: 'Census Tact'
  },
  census_block: {
    url: 'mapbox://mattsayre.3cpval7a',
    source: 'census-blocks',
    name: 'blocks',
    data_id: 'GEOID10',
    label: 'Census Block'
  },
  zip_code: {
    url: 'mapbox://mattsayre.857dv4qz',
    source: 'zip-codes',
    name: 'cb_2018_us_zcta510_500k',
    data_id: 'ZCTA5CE10'
    label: 'ZIP Code'
  }
}

# Our data layer is added above this layer
layer_position = "building"

window.initialize_mapboxgl = (elmID) ->
  mapboxgl.accessToken = MAPBOX_API_KEY
  maxZoom = 14

  map = new mapboxgl.Map({
    container: elmID,
    style: 'mapbox://styles/mapbox/light-v9',
    center: MAPBOX_LOCATION,
    zoom: MAPBOX_ZOOM,
    maxZoom: maxZoom
  })

  # disable map rotation using right click + drag
  map.dragRotate.disable()

  # disable map rotation using touch rotation gesture
  map.touchZoomRotate.disableRotation()

  # Add zoom and rotation controls to the map.
  map.addControl(new mapboxgl.NavigationControl({showCompass: false}))

  $('.leaflet-bottom').addClass('hide')

  map

get_map_loader = (map) ->
  map_id = map.getContainer().id
  loader_id = '#loader'
  $(loader_id)

clearMap = (map) ->
  if popup
    popup.remove()

  for id, layer of layers
    if map.getLayer(layer.name)
      map.removeLayer(layer.name)
    if map.getSource(layer.source)
      map.removeSource(layer.source)

addLayer = (map, group_by, data, test_type) ->
  layer = layers[group_by]
  if layer == undefined
    throw new Error('unknown layer: ' + group_by)

  map.addSource(layer.source, {
    type: "vector",
    url: layer.url
  })


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
  colorExpression.push("rgba(0, 0, 0, 0)")
  opacityExpression.push(0.0)
  lineExpression.push("rgba(0, 0, 0, 0)")

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
  }, layer_position)

  map.on('mouseenter',  layer.name, () ->
    map.getCanvas().style.cursor = 'pointer'
  )

  map.on('mouseleave', layer.name,  () ->
    map.getCanvas().style.cursor = ''
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

    content = "<h4>#{layer.label}: " + stats.id + "</h4>" +
      "<p>Tests in this #{layer.label}: <strong>" + stats.all_count + '</strong></p>' +
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

window.set_mapbox_groupby = (map, provider, group_by, test_type, label) ->
  loader = get_map_loader(map)
  loader.removeClass('hide')

  clearMap(map)

  $.ajax
    url: '/stats/groupby'
    type: 'POST'
    dataType: 'json'
    data:
      provider: provider
      group_by: group_by
      test_type: test_type
    success: (data) ->
      addLayer(map, group_by, data.result, test_type)

      loader.addClass('hide')
      disable_filters('map-filters', false)
    error: (request, statusText, errorText) ->
      err = new Error("get zip data failed")

      Sentry.setExtra("status_code", request.status)
      Sentry.setExtra("body",  request.responseText)
      Sentry.setExtra("response_status",  statusText)
      Sentry.setExtra("response_error",  errorText)
      Sentry.captureException(err)
