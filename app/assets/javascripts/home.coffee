bind_rating_stars = ->
  star_options =
    stars: 7
    min: 0
    max: 7
    step: 1
    displayOnly: false
    showClear: false
    showCaption: false
    size:'sm'

  $('.rating-container input').each ->
    $(this).rating star_options

disable_form_inputs = ->
  $('#form-container .form-fields input').prop('disabled', true)

set_coords = (accuracy, latitude, longitude) ->
  $('#submission_latitude').attr 'value', latitude
  $('#submission_longitude').attr 'value', longitude
  $("input[name='submission[accuracy]']").attr 'value', accuracy

  location_finished()

set_coords_by_geolocation = (position) ->
  set_coords(position.coords.accuracy, position.coords.latitude, position.coords.longitude)

block_callback = (err) ->
  if $('#location_geolocation').prop('checked')
    $('#location_button').html('Get My Location')

  $('#error-geolocation').modal('hide')
  $('#error-position_unavailable').modal('hide')

  if err.code == err.POSITION_UNAVAILABLE && is_safari()
    $('#error-position_unavailable').modal('show')
  else 
    $('#error-geolocation').modal('show')

  Sentry.setExtra("error_code", err.code)
  Sentry.setExtra("error_message", err.message)
  Sentry.captureException(err)

is_safari = ->
  ua = navigator.userAgent.toLowerCase()
  return (ua.indexOf('safari') != -1) && (ua.indexOf('chrome') == -1)

  
get_location = ->
  if navigator.geolocation
    location_start()
    navigator.geolocation.getCurrentPosition set_coords_by_geolocation, block_callback
  else
    location_error()
    if $('#location_geolocation').prop('checked')
        $('#location_button').html('Get My Location')
      $('#error-geolocation').modal('show')

ajax_interactions = ->
  $(document)
    .ajaxStart ->
      location_start()
    .ajaxStop ->
      location_finished()

check_fields_validity = ->
  is_valid = true

  unless $('#submission_monthly_price')[0].checkValidity()
    $('#submission_monthly_price').addClass('got-error')
    $('#price_error_span').removeClass('hide')
    is_valid = false
  else
    $('#submission_monthly_price').removeClass('got-error')
    $('#price_error_span').addClass('hide')

  unless $('#submission_provider_down_speed')[0].checkValidity()
    $('#submission_provider_down_speed').addClass('got-error')
    $('#speed_error_span').removeClass('hide')
    is_valid = false
  else
    $('#submission_provider_down_speed').removeClass('got-error')
    $('#speed_error_span').addClass('hide')

  is_valid

is_mobile_data = ->
  $(".checkboxes-container input[name='submission[testing_for]']:checked").val() == 'Mobile Data'

enable_speed_test = ->
  $('.test-speed-btn').on 'click', ->
    if check_fields_validity()
      $('#testing_speed').modal('show');

      setTimeout (->
        $('#start_ndt_test').click()
      ), 200

numeric_field_constraint = ->
  $('.numeric').keydown (e) ->
    if $.inArray(e.keyCode, [
        46
        8
        9
        27
        13
        110
        190
      ]) != -1 or e.keyCode == 65 and (e.ctrlKey == true or e.metaKey == true) or e.keyCode >= 35 and e.keyCode <= 40
      return
    if (e.shiftKey or e.keyCode < 48 or e.keyCode > 57) and (e.keyCode < 96 or e.keyCode > 105)
      e.preventDefault()

set_error_for_invalid_fields = ->
  $('#submission_monthly_price').focusout ->
    unless $('#submission_monthly_price')[0].checkValidity()
      $('#submission_monthly_price').addClass('got-error')
      $('#price_error_span').removeClass('hide')
    else
      $('#submission_monthly_price').removeClass('got-error')
      $('#price_error_span').addClass('hide')

  $('#submission_provider_down_speed').focusout ->
    unless $('#submission_provider_down_speed')[0].checkValidity()
      $('#submission_provider_down_speed').addClass('got-error')
      $('#speed_error_span').removeClass('hide')
      is_valid = false
    else
      $('#submission_provider_down_speed').removeClass('got-error')
      $('#speed_error_span').addClass('hide')

location_start = ->
  if $('#location_geolocation').prop('checked')
    $('#location_button').prop('innerHTML', 'Loading...')

  if $('#location_address').prop('checked')
    $('#location_next_button').prop('innerHTML', 'Loading...');

location_finished = ->
  if $('#location_geolocation').prop('checked') && $('#location_success').prop('value', 'true')
    $('#location_button').prop('innerHTML', 'Location Success!')
    $('#location_button').addClass('button-disabled')
    $('#location_button').prop('disabled', true)

  if $('#location_address').prop('checked')
    $('#location_next_button').prop('innerHTML', "Let's begin");

  $("#location_success").attr 'value', true
  $('.test-speed-btn').prop('disabled', false)
  $('.location-warning').addClass('hide')
  $('#location_next_button').attr('disabled', false)
  $('#location_next_button').removeClass('button-disabled')

location_error = ->
  if $('#location_geolocation').prop('checked')
    $('#location_button').prop('innerHTML', 'Get My Location')

  $('#error-geolocation').modal('show')

ajax_interactions = ->
  $(document)
    .ajaxStart ->
      lcoation_start()
    .ajaxStop ->
      location_finished()

places_autocomplete = ->
  placesAutocomplete = places({
    application_id: ALGOLIA_APP_ID,
    api_key: ALGOLIA_API_KEY,
    container: window.document.querySelector('#address-input')
  });

  placesAutocomplete.on 'change', (eventResult) ->
    if eventResult
      latlng = eventResult.suggestion.latlng
      set_coords(50, latlng.lat, latlng.lng)
  placesAutocomplete

$ ->
  bind_rating_stars()
  disable_form_inputs()
  numeric_field_constraint()

  if window.location.pathname == '/'
    enable_speed_test()
    set_error_for_invalid_fields()
    places_autocomplete()
    ajax_interactions()
    $(".checkboxes-container input[name='submission[location]']").each ->
      $(this).prop('checked', false)

  $('[rel="tooltip"]').tooltip({'placement': 'top'});
  $('#testing_for_button').attr('disabled', true)
  $(".checkboxes-container input[name='submission[testing_for]']").prop('checked', false)

  $('#take_test').on 'click', ->
    $('.title-container').addClass('hidden');
    $('#form-container').removeClass('hide')
    $('#form-step-0 input').prop('disabled', false)
    $('#introduction').addClass('hide')
    $('.home-wrapper').addClass('mobile-wrapper-margin')

    $(".checkboxes-container input[name='submission[location]']").on 'change', ->
      $('#location_button').prop('disabled', false)
      if $("#location_success").prop('value') == 'false'
        $('#location_next_button').prop('disabled', true)
        $('#location_next_button').addClass('button-disabled')
      $(".checkboxes-container input[name='submission[location]']").each ->
        $(this).prop('checked', false)
      $(this).prop('checked', true)

      if $('#location_geolocation').prop('checked')
        $('#location_button').removeClass('hide')
        $('#location-address-input').addClass('hide')

      if $('#location_address').prop('checked')
        $('#location_button').addClass('hide')
        $('#location-address-input').removeClass('hide')

      if $('#location_disabled').prop('checked')
        $('#location_button').addClass('hide')
        $('#location-address-input').addClass('hide')
        $('#location_next_button').attr('disabled', false)
        $('#location_next_button').removeClass('button-disabled')

  $('#location_button').on 'click', ->
    $('#location_button').prop('innerHTML', 'Loading...')
    get_location()

  $('#location_next_button').on 'click', ->
    if $('#location_geolocation').prop('checked')
      if $("#location_success").prop('value') == 'false'
        navigator.geolocation.getCurrentPosition set_coords_by_geolocation, block_callback
      show_step_one()

    if $('#location_address').prop('checked')
      if $("#location_success").prop('value') == 'true'
        show_step_one()
      else
        $('#address-input').addClass('error-input')
        $('#location_next_button').attr('disabled', true)
        $('#location_next_button').removeClass('button-disabled')

        setTimeout (->
          $('#address-input').removeClass('error-input');
        ), 2500

    if $('#location_disabled').prop('checked')
      show_step_one()


  $(".checkboxes-container input[name='submission[testing_for]']").on 'change', ->
    $(".checkboxes-container input[name='submission[testing_for]']").each ->
      $(this).prop('checked', false)
    $(this).prop('checked', true)
    $('#testing_for_button').attr('disabled', !$(".checkboxes-container input[name='submission[testing_for]']").is(':checked'));

  $('#testing_for_button').on 'click', ->
    testing_for = $(".checkboxes-container input[name='submission[testing_for]']:checked").data('target')
    $(testing_for).removeClass('hide')
    $(testing_for + ' input').prop('disabled', false)
    $(testing_for + ' select').prop('disabled', false)
    $('#form-step-1').addClass('hide')

show_step_one = ->
  $('#form-step-0').addClass('hide')
  $('#form-step-1').removeClass('hide')
  $('#form-step-1 input').prop('disabled', false)
  $('.test-speed-btn').prop('disabled', false)
  $('.location-warning').addClass('hide')
