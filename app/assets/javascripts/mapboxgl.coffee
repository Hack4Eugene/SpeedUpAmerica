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

  # Add zoom and rotation controls to the map.
  map.addControl(new mapboxgl.NavigationControl())

  $('.leaflet-bottom').addClass('hide')

  map

get_map_loader = (map) ->
  map_id = map.getContainer().id

  if map_id == 'all_results_map'
    loader_id = '#loader'
  else if map_id == 'zip_code_map'
    loader_id = '#stats_loader'

  $(loader_id)

window.set_mapbox_zip_data_gl = (map, provider, date_range, group_by='zip_code', test_type='download') ->
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
      clearMap(map)

      map.addLayer({
        'id': 'zip-codes',
        'type': 'fill',
        'source': {
          'type': 'geojson',
          'data':  {
              'type': 'FeatureCollection',
              'features': data
          },
        },
        'paint': {
          'fill-antialias': true,
          'fill-outline-color': '#000000',
          'fill-color':['get', 'color'],
          'fill-opacity': ['get', 'fillOpacity']
        }    
      });

      map.on('click', 'zip-codes', (e) ->
        feature = e.features[0]
      
        content = '<h2>Test Results for ' + feature.properties.title + ':</h2>' +
          '<p>Tests in this zip code: <strong>' + feature.properties.count + '</strong></p><br />' +
          "<p>Median #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" + feature.properties.median_speed + ' Mbps</strong></p>' +
          "<p>Fastest #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" + feature.properties.fast_speed + ' Mbps</strong></p>'

        popup = new mapboxgl.Popup()
          .setLngLat(e.lngLat)
          .setHTML(content)
          .addTo(map);
      )

      map.on('mouseenter', 'zip-codes', () -> 
        map.getCanvas().style.cursor = 'pointer';
      )
 
      map.on('mouseleave', 'zip-codes',  () -> 
        map.getCanvas().style.cursor = '';
      )

      loader.addClass('hide')
      disable_filters('map-filters', false)

popup = null

clearMap = (map) ->
  if popup 
    popup.remove()
  
  if map.getLayer('zip-codes')
    map.removeLayer('zip-codes')
  if map.getSource('zip-codes')
    map.removeSource('zip-codes')

  if map.getLayer('census-tracts')
    map.removeLayer('census-tracts')
  if map.getSource('census-tracts')
    map.removeSource('census-tracts')

window.set_mapbox_census_data_gl = (map, provider, date_range, test_type, zip_code, census_code, type) ->
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
      clearMap(map)

      map.addLayer({
        'id': 'census-tracts',
        'type': 'fill',
        'source': {
          'type': 'geojson',
          'data':  {
              'type': 'FeatureCollection',
              'features': data
          },
        },
        'paint': {
          'fill-antialias': true,
          'fill-outline-color': '#000000',
          'fill-color':['get', 'color'],
          'fill-opacity': ['get', 'fillOpacity']
        }    
      }); 

      map.on('click', 'census-tracts', (e) ->
        feature = e.features[0]
      
        content = "<p>Tests in census tract #{feature.properties.title}: <strong>#{feature.properties.count}</strong></p>" +
          "<p>Median #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" + feature.properties.median_speed + ' Mbps</strong></p>' +
          "<p>Fastest #{test_type[0].toUpperCase() + test_type[1..-1]} Speed: <strong>" + feature.properties.fast_speed + ' Mbps</strong></p>'
       
        popup = new mapboxgl.Popup()
          .setLngLat(e.lngLat)
          .setHTML(content)
          .addTo(map);
      )

      map.on('mouseenter', 'zip-codes', () -> 
        map.getCanvas().style.cursor = 'pointer';
      )
 
      map.on('mouseleave', 'zip-codes',  () -> 
        map.getCanvas().style.cursor = '';
      )

      loader.addClass('hide')
      disable_filters('map-filters', false)

