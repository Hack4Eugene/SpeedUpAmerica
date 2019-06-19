
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
      map.removeLayer('zip-codes')
      map.removeLayer('census-tracts')
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

      loader.addClass('hide')
      disable_filters('map-filters', false)

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
      map.removeLayer('zip-codes')
      map.removeLayer('census-tracts')
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

      loader.addClass('hide')
      disable_filters('map-filters', false)

