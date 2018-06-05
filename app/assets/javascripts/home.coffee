bind_rating_stars = ->
  star_options =
    stars: 5
    min: 0
    max: 5
    step: 1
    displayOnly: false
    showClear: false
    showCaption: false
    size:'sm'

  $('.rating-container input').each ->
    $(this).rating star_options

disable_form_inputs = ->
  $('#form-container .form-fields input').prop('disabled', true)

is_buisness_test = ->
  !$('#form_step_3').hasClass('hide')

set_coords = (position) ->
  $('#submission_latitude').attr 'value', position.coords.latitude
  $('#submission_longitude').attr 'value', position.coords.longitude
  $.ajax
      url: 'home/get_location_data'
      type: 'POST'
      dataType: 'json'
      data:
        latitude: position.coords.latitude
        longitude: position.coords.longitude
      success: (data) ->
        $("input[name='submission[address]']").attr 'value', data['address']
        $("input[name='submission[zip_code]']").attr 'value', data['zip_code']
        $('.test-speed-btn').prop('disabled', false)
        $('.location-warning').addClass('hide')
        $('#take_test').prop('disabled', false)
        $('#take_test').addClass('opacity-100')

block_callback = (error) ->
  $('#error-geolocation').modal('show');

get_location = ->
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition set_coords, block_callback

check_provider_speed_limits = (id) ->
  ($("##{id}").val() <= 0 || $("##{id}").val() > 9999) && ($("##{id}").val() != '')

check_buisness_provider_limits = (klass) ->
  ($(".#{klass}").val() <= 0 || $(".#{klass}").val() > 9999) && ($(".#{klass}").val() != '')

check_fields_validity = ->
  is_valid = true

  unless $('#submission_monthly_price')[0].checkValidity()
    $('#submission_monthly_price').addClass('got-error')
    $('#price_error_span').removeClass('hide')
    is_valid = false
  else
    $('#submission_monthly_price').removeClass('got-error')
    $('#price_error_span').addClass('hide')

  if check_provider_speed_limits('submission_provider_down_speed')
    $('#submission_provider_down_speed').addClass('got-error')
    $('#speed_error_span').removeClass('hide')
    $('#speed_error_span').text('Error: This value should be between 0 to 9999.')
    is_valid = false
  else
    $('#submission_provider_down_speed').removeClass('got-error')
    $('#speed_error_span').addClass('hide')

  if is_buisness_test()
    if check_buisness_provider_limits('buisness-provider-speed')
      $('.buisness-provider-speed').addClass('got-error')
      $('#buisness_speed_error_span').removeClass('hide')
      $('#buisness_speed_error_span').text('Error: This value should be between 0 to 9999.')
      is_valid = false
    else
      $('.buisness-provider-speed').removeClass('got-error')
      $('#buisness_speed_error_span').addClass('hide')

  is_valid

start_speed_test = ->
  $('.test-speed-btn').on 'click', ->
    if navigator['onLine']
      $('.internet-error').addClass('hide') if $('.internet-error').is ':visible'

      if check_fields_validity()
        $('#testing_speed').modal('show');
        SomApi.config.testServerEnabled = false
        SomApi.config.userInfoEnabled = false
        SomApi.config.latencyTestEnabled = true
        SomApi.config.uploadTestEnabled = true
        SomApi.config.progress.enabled = true
        SomApi.config.progress.verbose = true
        SomApi.startTest()
    else
      $('.internet-error').removeClass('hide')

  onTestCompleted = (testResult) ->
    $('#submission_actual_upload_speed').val(testResult.upload)
    $('#submission_actual_down_speed').val(testResult.download)
    $('#submission_ping').val(testResult.latency)
    $("#new_submission").submit()

  onError = (error) ->
    msgDiv.html(['Error', error.code, ':', error.message].join(' '))

  if $('#rails_env_constant').val() == 'production'
    SomApi.account = 'SOM582f308b88201'
    SomApi.domainName = 'speedupsanjose.com'
  else
    SomApi.account = 'SOM5818352c44bb3'
    SomApi.domainName = 'speed.fractus.ws'

  SomApi.config.sustainTime = 2
  SomApi.onTestCompleted = onTestCompleted
  SomApi.onError = onError
  SomApi.onProgress = onProgress

  onProgress = (progress) ->
    console.log progress.type
    console.log progress.pass
    console.log progress.percentDone
    console.log progress.currentSpeed
    $('#progress-ul').html("<li>Progress Type: " + progress.type + "</li>" +
                           "<li>Pass: " + progress.pass + "</li>" +
                           "<li>Percent Done: " + progress.percentDone + "% </li>" +
                           "<li>Current Speed: " + progress.currentSpeed + " Mbps </li>")
    $('#testing_speed #progress_type').html progress.type
    $('#testing_speed #pass').html progress.pass
    $('#testing_speed #percentage_done').html progress.percentDone + "%"
    $('#testing_speed #current_speed').html progress.currentSpeed + " Mbps"

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

$ ->
  bind_rating_stars()
  disable_form_inputs()
  numeric_field_constraint()

  if window.location.pathname == '/'
    get_location()
    start_speed_test()

  $('[rel="tooltip"]').tooltip({'placement': 'top'});
  $('#testing_for_button').attr('disabled', true)
  $('.test-speed-btn').prop('disabled', true)

  $('#take_test').on 'click', ->
    $('.title-container').addClass('hidden');
    $('#form-container').removeClass('hide')
    $('#form-step-1 input').prop('disabled', false)
    $('#introduction').addClass('hide')
    $('.home-wrapper').addClass('mobile-wrapper-margin')
    scroll_to_top()

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
    scroll_to_top()

  $('.take-test-text').click ->
    $('#take_test').click() unless($('#take_test').is ':disabled')

  scroll_to_top = ->
    $('html, body').animate { scrollTop: 0 }, 'slow'

  $('.view-result-text').click ->
    $('#view_results_link').click()

  $('.checkboxes-container').on 'keyup', '.checkbox', (e) ->
    keyCode = e.keyCode or e.which
    if keyCode == 9
      $(this).find("input[type='checkbox']").prop("checked", true)
      $(this).siblings('.checkbox').find("input[type='checkbox']").prop("checked", false)
      $('#testing_for_button').prop('disabled', false)
