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

window.initialize_mapbox = (map) ->
  L.mapbox.accessToken = MAPBOX_API_KEY;
  maxZoom = isIE() && 12 || 14

  map = L.mapbox.map(map, 'mapbox.light', { maxZoom: maxZoom }).setView([44.0639066, -120.67382], 7)

  map.scrollWheelZoom.disable();

  map.on 'click', (e) ->
    map.scrollWheelZoom.enable();

  $('.leaflet-bottom').addClass('hide')

  map

get_map_loader = (map) ->
  map_id = map.getContainer().id

  if map_id == 'all_results_map'
    loader_id = '#loader'
  else if map_id == 'zip_code_map'
    loader_id = '#stats_loader'

  $(loader_id)

window.set_mapbox_zip_data = (map, provider, date_range, group_by='zip_code', test_type='download') ->
  loader = get_map_loader(map)
  loader.removeClass('hide')
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
                    '<p>Tests in this zip code: <strong>' + feature.properties.count + '</strong></p><br />' +
                    "<p>Median #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" + feature.properties.median_speed + ' Mbps</strong></p>' +
                    "<p>Fastest #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" + feature.properties.fast_speed + ' Mbps</strong></p>'
          layer.bindPopup content, closeButton: false
      ).addTo map

      loader.addClass('hide')
      disable_filters('map-filters', false)

window.set_mapbox_census_data = (map, provider, date_range, test_type, zip_code, census_code, type) ->
  loader = get_map_loader(map)
  loader.removeClass('hide')
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
          content = "<p>Tests in census tract #{feature.properties.title}: <strong>#{feature.properties.count}</strong></p>" +
                    "<p>Median #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" + feature.properties.median_speed + ' Mbps</strong></p>' +
                    "<p>Fastest #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" + feature.properties.fast_speed + ' Mbps</strong></p>'
          layer.bindPopup content, closeButton: false
      ).addTo map

      loader.addClass('hide')
      disable_filters('map-filters', false)