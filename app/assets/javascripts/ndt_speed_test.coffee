bind_ndt_speed_calculation = ->
  ndtServer = undefined
  ndtPort = '3010'
  ndtProtocol = 'wss'
  ndtPath = '/ndt_protocol'
  ndtUpdateInterval = 1000

  success = (position) ->
    xhr = new XMLHttpRequest
    currentLocationURL = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=' + position.coords.latitude + '&lon=' + position.coords.longitude + '&zoom=18&addressdetails=1'
    xhr.open 'GET', currentLocationURL, true
    xhr.send()

    xhr.onreadystatechange = ->
      if xhr.readyState == 4
        if xhr.status == 200
          currentLoc = JSON.parse(xhr.responseText)
          console.log 'Location received'
          $('#mobile-container').append '<div id="mobile-approx-loc"></div>'
          $('#approx-loc, #mobile-approx-loc').append '<p>Searching from:</p><p>' + currentLoc.address.road + ', ' + currentLoc.address.city + ', ' + currentLoc.address.state + '</p>'
        else
          console.log 'Location lookup failed'
      return

    return

  error = (error) ->
    document.getElementById('msg').innerHTML = 'ERROR(' + error.code + '): ' + error.message
    return

  getNdtServer = ->
    xhr = new XMLHttpRequest
    mlabNsUrl = 'https://mlab-ns.appspot.com/ndt_ssl?format=json'
    xhr.open 'GET', mlabNsUrl, true
    xhr.send()

    xhr.onreadystatechange = ->
      if xhr.readyState == 4
        if xhr.status == 200
          ndtServer = JSON.parse(xhr.responseText).fqdn
          ndtServerIp = JSON.parse(xhr.responseText).ip
          console.log 'Using M-Lab Server ' + ndtServer
          document.getElementById('submission_hostname').value = ndtServer;
        else
          console.log 'M-Lab NS lookup failed.'
      return

    return

  getNdtServer()
  uncheckAcknowledgement()
  NDT_meter = new NDTmeter('#ndt-svg')
  $('#start_ndt_test').on 'click', ->
    NDT_client = new NDTjs(ndtServer, ndtPort, ndtProtocol, ndtPath, NDT_meter, ndtUpdateInterval)
    NDT_client.startTest()
    return
  if 'geolocation' of navigator
    navigator.geolocation.getCurrentPosition success, error

(($) ->
  window.NdtSpeedTest || (window.NdtSpeedTest = {})

  NdtSpeedTest.init = ->
    init_controls()

  init_controls = ->
    bind_ndt_speed_calculation()
).call(this)
