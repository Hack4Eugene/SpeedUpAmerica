disable_form_inputs = ->
  $('#form-container .form-fields input').prop('disabled', true)

set_coords = (accuracy, latitude, longitude) ->
  $('#region_submission_latitude').attr 'value', latitude
  $('#region_submission_longitude').attr 'value', longitude
  $("input[name='region_submission[accuracy]']").attr 'value', accuracy

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

  unless $('#region_submission_monthly_price')[0].checkValidity()
    $('#region_submission_monthly_price').addClass('got-error')
    $('#price_error_span').removeClass('hide')
    is_valid = false
  else
    $('#region_submission_monthly_price').removeClass('got-error')
    $('#price_error_span').addClass('hide')

  is_valid

is_mobile_data = ->
  $(".checkboxes-container input[name='submission[testing_for]']:checked").val() == 'Mobile Data'

enable_speed_test = ->
  $('#test-speed-btn').on 'click', ->
    if check_fields_validity()
      $('#testing_speed').modal('show');

      setTimeout (->
        console.log('starting regional ndt test...');
        $('#region_start_ndt_test').click()
      ), 200

enable_submit = ->
# SUBMIT BUTTON
	$('#submit-btn').on 'click', ->
		console.log('submit-btn clicked');
		setTimeout (->
			console.log('starting submittal of data...');
			$('#new_region_submission').submit();
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


access_start = ->
  #if $('#access_have').prop('checked')
    #$('#test-speed-btn').prop('innerHTML', 'Loading...');

  #if $('#access_donothave').prop('checked')
    #$('#test-speed-btn').prop('innerHTML', 'Loading...');


access_finished = ->
  if $('#access_have').prop('checked')
    $('#test-speed-btn').prop('innerHTML', "Let's begin");
    $('#location-address-input').removeClass('hide')

  if $('#access_donothave').prop('checked')
    $('#test-speed-btn').prop('innerHTML', "Let's begin");
    $('#location-address-input').removeClass('hide')


  $("#location_success").attr 'value', true
  $('#test-speed-btn').prop('disabled', false)
  $('.location-warning').addClass('hide')
  #$('#test-speed-btn').attr('disabled', false)
  $('#test-speed-btn').removeClass('button-disabled')

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
				$('#region_submission_address').attr 'value', eventResult.suggestion.value
				$('#region_submission_zip_code').attr 'value',eventResult.suggestion.postcode
				#console.log('address:'+eventResult.suggestion.value)
				#console.log('zip:'+eventResult.suggestion.postcode)
  placesAutocomplete

# This function only works on the region page
region_take_the_test = ->
  $('.title-container').addClass('hidden')
  $('#form-container').removeClass('hide')
  $('#form-step-0 input').prop('disabled', false)
  $('#introduction').addClass('hide')
  $('.home-wrapper').addClass('mobile-wrapper-margin')


# 1st box clicked
  $(".checkboxes-container input[name='region_submission[access]']").on 'change', ->

    $('#agree-div').removeClass('hide')
    $(".checkboxes-container input[name='region_submission[access]']").each ->
      $(this).prop('checked', false)
    $(this).prop('checked', true)
    $('#agree').prop('checked', false)
    $('#address-div').addClass('hide')
    $('#addresswithinternet').addClass('hide')
    $('#addresswithoutinternet').addClass('hide')
    $('#price-div').addClass('hide')
    $('#connectedornot-div').addClass('hide')
    $('#testbutton-div').addClass('hide')
    $('#testbutton-div').addClass('button-disabled')
    $('#submitbutton-div').addClass('hide')
    $('#submitbutton-div').addClass('button-disabled')




# 1st box  choice 1 checked - HAVE ACCESS

  $("#agree").on 'change', ->
    if $('#agree').prop('checked')
      if $('#access_have').prop('checked')
        $('#access_donothave').prop('checked',false)
        #$('#connected-with').removeClass('hide')
        #$('#connectedornot-div').removeClass('hide')
        $('#connectedornot-div').addClass('hide')
        $('#price-div').removeClass('hide')
        $('#address-div').removeClass('hide')
        $('#nointernet').addClass('hide')
        $('#addresswithinternet').removeClass('hide')
        $('#addresswithoutinternet').addClass('hide')
        $('#access-div').addClass('shrink') #shrink the first div
        $('#price-text-connected').removeClass('hide')
        $(".checkboxes-container input[name='region_submission[whynoaccess]']").each ->
          $(this).prop('checked', false)
        window.scrollBy(0,150)

# 1st box choice 2 checked - DO NOT HAVE ACCESS
      if $('#access_donothave').prop('checked')
        $('#access_have').prop('checked',false)
        $('#price-div').addClass('hide')
        $('#connectedornot-div').removeClass('hide')
        $('#address-div').addClass('hide')
        $('#nointernet').removeClass('hide')
        $('#connected-with').addClass('hide')
        $('#addresswithinternet').addClass('hide')
        $('#addresswithoutinternet').removeClass('hide')
        $('#access-div').addClass('shrink') #shrink the first div
        $('#price-text-connected').addClass('hide')
        $('#price-text-notconnected').removeClass('hide')
        window.scrollBy(0,150)

    else
      $('#address-div').addClass('hide')
      $('#addresswithinternet').addClass('hide')
      $('#addresswithoutinternet').addClass('hide')
      $('#price-div').addClass('hide')
      $('#connectedornot-div').addClass('hide')
      $('#testbutton-div').addClass('hide')

#if $('#access_have').prop('checked', false) and $('#access_donothave').prop('checked', false)
          #$('#connectedornot-div').addClass('hide')

# 2nd box group 1 check  - HOW CONNECTED
  $(".checkboxes-container input[name='region_submission[connected_with]']").on 'change', ->
      $('#price-div').removeClass('hide')

      $(".checkboxes-container input[name='region_submission[connected_with]']").each ->
        $(this).prop('checked', false)
      $(this).prop('checked', true)


# 2nd box group 2 check - WHY NOT CONNECTED
  $(".checkboxes-container input[name='region_submission[whynoaccess]']").on 'change', ->
    
      $('#price-div').addClass('hide')
      $('#address-div').removeClass('hide')


      $('#access-div').addClass('shrink') #shrink the first div
      $(".checkboxes-container input[name='region_submission[whynoaccess]']").each ->
        $(this).prop('checked', false)
      $(this).prop('checked', true)
			window.scrollBy(0,200) 


# 3rd box - PRICE
  $("#region_submission_monthly_price").on 'change', ->
      $('#address-div').removeClass('hide')

# 4th box filled in - ADDRESS
location_finished = ->
  if $('#address-input').prop('value', 'true')
    if $('#access_have').prop('checked')
      $('#testbutton-div').removeClass('hide')
      $('#test-speed-btn').removeClass('button-disabled')
      $('#submitbutton-div').addClass('hide')
      $('#submit-btn').prop('disabled', true)
      #console.log('address-input val:' + $('#address-input').val());
      #console.log('address-input prop val:' + $('#address-input').prop('value'));
      #console.log('address-input placeholder:' + $('#address-input').attr('placeholder'));
      #console.log('address-input textContent:' + $('#address-input').textContent);
      window.scrollBy(0,280)	
    else
      $('#submitbutton-div').removeClass('hide')
      $('#submit-btn').prop('disabled', false)
      $('#testbutton-div').addClass('hide')
      $('#test-speed-btn').addClass('button-disabled')


$ ->
  disable_form_inputs()
  numeric_field_constraint()

  thispath = window.location.pathname
  thispatharray = thispath.split('/')
		thispathone = thispatharray[1]
  

  if thispathone == 'region'
    enable_speed_test()
    enable_submit()
    #set_error_for_invalid_fields()
    places_autocomplete()
    ajax_interactions()
    $(".checkboxes-container input[name='region_submission[location]']").each ->
      $(this).prop('checked', false)

    # Start the test when the user clicks either the button or the nav link
    # $('#take_test, .nav-link-take-test').on 'click', region_take_the_test

    # Start the test if the user arrived via a link pointing to the test
    # if window.location.hash == '#take_test'
    #window.scrollTo(0, 0)
    region_take_the_test()

  $('[rel="tooltip"]').tooltip({'placement': 'top'});
  $('#testing_for_button').attr('disabled', true)
  $(".checkboxes-container input[name='region_submission[testing_for]']").prop('checked', false)

