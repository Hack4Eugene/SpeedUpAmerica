function closeAllTheThings() {
  $('#sidebar').removeClass('extended');
}

$( window ).resize(function() {
  if (($(document).width() > 501)) {
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
});
