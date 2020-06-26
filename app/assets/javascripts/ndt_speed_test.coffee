bind_ndt_speed_calculation = ->
  ndtServer = undefined
  ndtPort = '3010'
  ndtProtocol = 'wss'
  ndtPath = '/ndt_protocol'
  ndtUpdateInterval = 1000

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

          # Track NDT server used
          Sentry.setExtra("mlab_server", ndtServer)
        else
          console.log 'M-Lab NS lookup failed.'

          # Track NDT server used
          Sentry.setExtra("mlab_server", 'failed')
      return
    return

  getNdtServer()

  NDT_meter = new NDTmeter('#ndt-svg')
  $('#start_ndt_test').on 'click', ->
    NDT_client = new NDTjs(ndtServer, ndtPort, ndtProtocol, ndtPath, NDT_meter, ndtUpdateInterval)
    NDT_client.startTest()
    return

(($) ->
  window.NdtSpeedTest || (window.NdtSpeedTest = {})

  NdtSpeedTest.init = ->
    init_controls()

  init_controls = ->
    bind_ndt_speed_calculation()
).call(this)
