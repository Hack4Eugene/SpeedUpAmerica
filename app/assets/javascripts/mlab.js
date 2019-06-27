// purely launch workaround for #114
function getCurrentValues() {
  var currentMetricOption = $('#selectMetric option:selected').text();
  var currentYearOption = $('#selectYear option:selected').text();
  // get index
};


/**
 * Creates the map legend that will appear in the lower right corner of the map.
 *
 * @returns {object} DOM object for map legend
 */
function addLegend() {
  var legend = L.control({position: 'bottomleft'});

  legend.onAdd = function(map) {
    var div = L.DomUtil.create('div', 'info legend'),
      grades = [0, 5, 10, 25, 50];

    var i;
    div.innerHTML = '';
    for ( i = grades.length - 1; i >= 0; i-- ) {
      div.innerHTML +=
        '<i style="background:' + getPolygonColor(grades[i]) +
        '"></i> ' + (i == grades.length ? '0' : grades[i]) + (grades[i - 1] ?
          '&ndash;' + grades[i - 1] + ' Mbps<br/>' : '+ Mbps<br/>');
    }
    div.innerHTML += '<i style="background: black; opacity: .2">' +
      '</i>Insuff. data';
    return div;
  };

  legend.addTo(map);
}

/**
 * Add various map controls to the lower left corner of the map.
 *
 * @returns {object} DOM object for the controls box
 */
function addControls() {
  var controls = L.control({position: 'bottomleft'});

  controls.onAdd = function(map) {
    var controls = L.DomUtil.create('div', 'info controls'),
      labelMetric = L.DomUtil.create('span', 'mapControls', controls),
      selectMetric = L.DomUtil.create('select', 'mapControls', controls),
      labelYear = L.DomUtil.create('span', 'mapControls', controls),
      selectYear = L.DomUtil.create('select', 'mapControls', controls);

    if ( polygonType == 'hex' ) {
      var labelRes = L.DomUtil.create('span', 'mapControls', controls),
        selectRes = L.DomUtil.create('select', 'mapControls', controls);
      labelRes.innerHTML = 'Res.';
      selectRes.innerHTML = '<option value="low">Low</option>' +
        '<option value="medium">Medium</option>' +
        '<option value="high">High</option>';
      selectRes.setAttribute('id', 'selectRes');
    }

    var	checkAnimate = L.DomUtil.create('div', 'mapControls', controls),sliderMonth = L.DomUtil.create('div', 'mapControls', controls),dateOptions = '';

    var yearSelected;
    for ( var year in dates ) {
      yearSelected =  year == currentYear ? 'selected="selected"' : '';
      dateOptions += '<option value="' + year + '"' + yearSelected +
        '>' + year + '</option>';
    }

    checkAnimate.innerHTML = '<span id="playAnimation" class="paused"></span>';

    sliderMonth.setAttribute('id', 'sliderMonth');
    // Prevent the entire map from dragging when the slider is dragged.
    L.DomEvent.disableClickPropagation(sliderMonth);


    labelMetric.innerHTML = 'Show me';
    selectMetric.innerHTML = '<option value="download_median">' +
      'Download speeds</option><option value="upload_median">' +
      'Upload speeds</option>';
    selectMetric.setAttribute('id', 'selectMetric');
    selectMetric.setAttribute('class', 'form-control');

    labelYear.innerHTML = 'from';
    selectYear.innerHTML = dateOptions;
    selectYear.setAttribute('id', 'selectYear');
    selectYear.setAttribute('class', 'form-control');

    return controls;
  };

  controls.addTo(map);


  var metricChoices = $(".leaflet-control > span, .leaflet-control > select").slice(0,4);
  $(".leaflet-control > div.mapControls").wrapAll("<div class='sliderElements'></div>");
  metricChoices.wrapAll("<div class='metricControls'></div>");

  var elems;
  if ( polygonType != 'hex' ) {
    elems = [selectYear, selectMetric];
  } else {
    elems = [selectYear, selectMetric, selectRes];
  }
  elems.forEach( function(elem) {
    elem.addEventListener('change',
      function (e) { updateLayers(e, 'update'); });
  });

  // Can't instantiate the slider until after "controls" is actually added to
  // the map.
}

/**
 * Update the map when some event gets triggered that requires the map to
 * displays something else.
 *
 * @param {object} e Event object
 * @param {string" mode What state are we in? New or update?
 */
function updateLayers(e, mode) {
  var year = $('#selectYear').val(),
    metric = $('#selectMetric').val();

  var resolution = polygonType == 'hex' ? $('#selectRes').val() : '';

  // If the year was changed then we need to update the slider and set its
  // value to the first configured month for that year.

}

/**
 * Determines the color of a polygon based on a passed metric.
 *
 * @param {number} val Metric to evaluate
 * @returns {string} A string representing the color
 */
function getPolygonColor(val) {
  return val >= 50 ? '#F57F17' :
    val >= 25  ? '#F9A825' :
    val >= 10  ? '#FBC02D' :
    val >= 5  ? '#FFEB3B' :
    val >= 0   ? '#FFEE58' : 'transparent';
}

/**
 * Fetches layer data from the server.
 *
 * @param {string} url URL where resource can be found
 * @param {function} callback Callback to pass server response to
 */
function getLayerData(url, callback) {
  if ( geoJsonCache[url] ) {
    console.log('Using cached version of ' + url);
    callback(geoJsonCache[url]);
  } else {
    console.log('Fetching and caching ' + url);
    $.get(url, function(resp) {
      // If we're dealing with a TopoJSON file, convert it to GeoJSON
      if ('topojson' == url.split('.').pop()) {
        var geojson = {
          'type': 'FeatureCollection',
          'features': null
        };
        geojson.features = omnivore.topojson.parse(resp);
        resp = geojson;
      }
      geoJsonCache[url] = resp;
      callback(resp);
    }, 'json');
  }
  getCurrentValues();
}

/**
 * Applies a layer to the map.
 *
 * @param {string} layer Name of layer to set
 * @param {string} year Year of layer to set
 * @param {string} month Month of layer to set
 * @param {string} metric Metric to be represented in layer
 * @param {string" mode What state are we in? New or update?
 * @param {string} [resolution] For hexbinned map, granularity of hex layer
 */
function setPolygonLayer(layer, year, month, metric, mode, resolution) {
  var polygonUrl;
  var dataUrl;

  // Create the layer from the cache if this is a newly loaded page
  if ( mode == 'new' ) {
    geoLayers[layer]['layer'] = L.geoJson(JSON.parse(
      JSON.stringify(geoLayers[layer]['cache'])));
  }

  // Don't display spinner if animation is happening
  if ( $('#playAnimation').hasClass('paused') === false ) {
    $('#spinner').css('display', 'block');
  }

  month = month < 10 ? '0' + month : month;
  if ( polygonType != 'hex' ) {
    var start = Date.UTC(year, month - 1, 1) / 1000;
    var end = Date.UTC(year, month, 1, 0, 0, -1) / 1000;
    dataUrl = geoLayers[layer]['dataUrl'] + start + ',' + end;
  } else {
    dataUrl = 'json/' + year + '_' + month + '-' + resolution + '.' +
      jsonType;
  }

  getLayerData(dataUrl, function(response) {
    var lookup = {};
    response.features.forEach(function(row) {
      lookup[row.properties[geoLayers[layer]['dbKey']]] = row.properties;
    });
    geoLayers[layer]['layer'].eachLayer(function(l) {
      cell = l.feature;

      var stats = lookup[cell.properties[geoLayers[layer]['geoKey']]];
      for (var k in stats) {
        if (stats.hasOwnProperty(k)) {
          cell.properties[k] = stats[k];
        }
      }

      var value = cell.properties[metric],
        polygonStyle = cell.polygonStyle = {};

      polygonStyle.weight = 1;
      polygonStyle.fillOpacity = 0.5;

      if ( ! value ) {
        polygonStyle.weight = 0.2;
        polygonStyle.fillOpacity = 0.015;
        polygonStyle.color = 'black';
        l.bindPopup(makeBlankPopup());
      } else if ( metric == 'download_median' &&
        cell.properties['download_count'] < minDataPoints ) {
        polygonStyle.weight = 0.5;
        polygonStyle.fillOpacity = 0.05;
        polygonStyle.color = 'black';
      } else if ( metric == 'upload_median' &&
        cell.properties['upload_count'] < minDataPoints ) {
        polygonStyle.weight = 0.5;
        polygonStyle.fillOpacity = 0.05;
        polygonStyle.color = 'black';
      } else {
        polygonStyle.color = getPolygonColor(value);
      }

      if ( metric == "download_median" &&
        cell.properties.download_count > 0 ) {
        l.bindPopup(makePopup(cell.properties));
      }
      if ( metric == "upload_median" &&
        cell.properties.upload_count > 0 ) {
        l.bindPopup(makePopup(cell.properties));
      }
      l.setStyle(cell['polygonStyle']);
    });

    // Add the layer controls if this is on page load, and if this
    // is the default layer we are dealing with then go ahead and add it
    // to the map.
    if ( mode == 'new' ) {
      layerCtrl.addOverlay(geoLayers[layer]['layer'], geoLayers[layer]['name']);
      if ( layer == defaultLayer ) {
        map.addLayer(geoLayers[layer]['layer']);
      }
    }

  });

  $('#spinner').css('display', 'none');
}

/**
 * Applies a scatter plot layer to the map.
 *
 * @param {string} year Year of layer to set
 * @param {string} month Month of layer to set
 * @param {string" mode What state are we in? New or update?
 */
function setPlotLayer(year, month, mode) {
  return;

  // Don't display spinner if animation is happening
  if ( $('#playAnimation').hasClass('paused') === false ) {
    $('#spinner').css('display', 'block');
  }

  month = month < 10 ? '0' + month : month;
  var plotUrl = 'json/' + year + '_' + month + '-plot.' + jsonType;

  if ( mode == 'update' ) {
    layerCtrl.removeLayer(plotLayer);
  }

  getLayerData(plotUrl, function(response) {
    if ( map.hasLayer(plotLayer) ) {
      map.removeLayer(plotLayer);
      var plotLayerVisible = true;
    }

    plotLayer = L.geoJson(response, {
      pointToLayer: function(feature, latlon) {
        return L.circleMarker(latlon, {
          radius: 1,
          fillColor: '#000000',
          fillOpacity: 1,
          stroke: false
        });
      }
    });

    layerCtrl.addOverlay(plotLayer, 'Plot layer');

    if ( plotLayerVisible ||
      (mode == 'new' && overlays['plot']['defaultOn']) ) {
      map.addLayer(plotLayer);
    }
  });

  $('#spinner').css('display', 'none');
}

/**
 * Takes a year and attempts to load the base layer date  into memory in the
 * background to speed switching between months for the current year.
 *
 * @param {string} year Year of layer to seed cache for
 */
function seedLayerCache(year) {
  var months = dates[year].slice(1),
    url;
  for ( i = 0; i < months.length; i++ ) {
    month = months[i] < 10 ? '0' + months[i] : months[i];
    if ( polygonType != 'hex' ) {
      url = 'json/' + year + '_' + month + '-' + polygonType +
        '.' + jsonType;
    } else {
      url = 'json/' + year + '_' + month + '-low.' + jsonType;
    }
    getLayerData(url, function(){ return false; });
  }
}

/**
 * Creates a popup with information about a polygon.
 *
 * @param {object} props Properties for a polygon
 * @returns {string} Textual information for the popup
 */
function makePopup(props) {
}
function makeBlankPopup() {
  var popup = "<h3 class='league-gothic'>This area doesn't have enough data yet!</h3><p>Help make our map more accurate by <a id='testSpeedEmptyPrompt' href='#' onClick='javascript:showTestingPanel()'>running your test</a> from an address in this area</a>!</p>";
  return popup;
}
/**
 * Run on page load to fetch and cache the geo file for a layer
 *
 * @param {string} layer The layer to fetch and cache
 */
function setupLayer(layer) {
  $.get(geoLayers[layer]['polygonFile'], function(resp) {
    var geojson = {
      'type': 'FeatureCollection',
      'features': omnivore.topojson.parse(resp)
    };

    geoLayers[layer]['cache'] = geojson;
    setPolygonLayer(layer, currentYear, currentMonth, 'download_median', 'new', 'low');

    if ( seedCache ) {
      seedLayerCache(currentYear);
    }
  }, 'json');
}

function closeAllTheThings() {
  $('#sidebar').removeClass('extended');
  $('#icons img').removeClass('selected');
  $('#ndt, #ndt-results, #about-ndt').hide();
  $('#ndt, #ndt-results, #extra-data, #about-ndt').hide();
}

function showTestingPanel() {
  // are there results yet?
  var results = document.getElementById('s2cRate');
  var resultsReceived = results.textContent;
  if ($('#test-icon').hasClass('selected')) {
    closeAllTheThings();
  }
  else {
    $('#icons img').removeClass('selected');
    $('#test-icon').addClass('selected');
    $('#sidebar').addClass('extended');
    $('#about-ndt').hide();
    if (resultsReceived !== "?") {
      $('#ndt-div').show();
      $('#ndt-results').show();
      $('#extra-data').show();
    }
    else {
      $('#ndt').show();
    }
  }

  $('#mobile-container').hide();
  if ($(document).width() < 700) {
    $('.metricControls, .sliderElements, .leaflet-control-layers').hide();
  }

}

$( window ).resize(function() {
  if ($('#header').hasClass('initial')) {
    return;
  }
  else if (($(document).width() > 501)) {
    $('.metricControls, .sliderElements, .leaflet-top.leaflet-left').show();
  }
  else if (($(document).width() < 500)) {
    $('.metricControls, .sliderElements, .leaflet-top.leaflet-left').hide();
  }
});

$(function() {
  /* Sets initial status on load for various divs */
  $('#testSpeed, #desktop-legend, .info.legend.leaflet-control, .leaflet-bottom.leaflet-left, .info.controls.leaflet-control, #socialshare, .leaflet-top.leaflet-right, .leaflet-control-layers').addClass('hidden');
  //$('.leaflet-top.leaflet-right').attr('id','layers-box');
  $('#header').addClass('initial');

  /* mobile bits */
  var mobileContainer = '<div id="mobile-container"></div>';
  $('#map').append(mobileContainer);
  var mobileMenuExtra = '<div id="mobile-menu">&equiv;</div>';
  $('.info.controls.leaflet-control').append(mobileMenuExtra);
  /*mobile bits */

  /* copying the mapbox legend into the mobile container to override placement for mobile devices */
  var attribution = $('div.leaflet-control-attribution.leaflet-control');
  $('div.info.legend.leaflet-control').append(attribution);
  $('div.info.legend.leaflet-control').clone().appendTo('#mobile-container');
  $('div.info.legend.leaflet-control').first().attr('id', 'desktop-legend');
  /* copying the mapbox legend into the mobile container */

  /* reset the display to initial desired state
  closeAllTheThings();*/

  $('#mobile-menu').click(function() {
    closeAllTheThings();
    $('#mobile-container, .sliderElements, .metricControls, #desktop-legend, .leaflet-control-layers').toggle();
  });

  $('#isp_user, #connection_type, #cost_of_service, #data_acknowledgement').change(function() {
    var formState = validateExtraDataForm();
    $('#take-test').toggle(formState);
  });
});

function uncheckAcknowledgement(){
  var datacheck = document.getElementById('data_acknowledgement');
  if($(datacheck).is(':checked')){
    $(datacheck).attr("checked", false);
  }
}


function submitExtraData() {
  var formData = $('#collector').serialize();
  $.ajax({
    method: 'GET',
    url: $('#collector').attr('action'),
    data: formData,
    statusCode: {
      201: function() {
        console.log('Data submitted successfully.');
      }
    },
    error: function(request, status, error) {
      err = new Error("submit extra data failed");

      Sentry.setExtra("status_code", request.status);
      Sentry.setExtra("body",  request.responseText);
      Sentry.setExtra("response_status",  statusText);
      Sentry.setExtra("response_error",  errorText);
      Sentry.captureException(err);
    }
  });
}

function validateExtraDataForm() {
  if ( $('#isp_user option:selected').val() == 'default' ) {
    return false;
  } else if ( $('#isp_user option:selected').val() == 'other' ) {
    $('#isp_user_text').toggle(true);
  } else {
    $('#isp_user_text').toggle(false);
  }
  if ( $('#connection_type option:selected').val() == 'default' ) {
    return false;
  }
  if ( $('#cost_of_service option:selected').val() == 'default' ) {
    return false;
  }
  if ( ! $('#data_acknowledgement').is(':checked') ) {
    return false;
  }
  return true;
}

function showOtherIspBox(val) {
  var element=document.getElementById('isp_user');
  if(val=='other') {
    $('#isp_user_text').show();
  }
  else {
    $('#isp_user_text').hide();
  }
}
