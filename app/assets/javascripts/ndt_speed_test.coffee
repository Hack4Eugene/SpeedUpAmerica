bind_ndt_speed_calculation = ->
  # ndtServer = undefined
  # ndtPort = '3010'
  # ndtProtocol = 'wss'
  # ndtPath = '/ndt_protocol'
  # ndtUpdateInterval = 1000

  # getNdtServer = ->
  #   xhr = new XMLHttpRequest
  #   mlabNsUrl = 'https://mlab-ns.appspot.com/ndt_ssl?format=json'
  #   xhr.open 'GET', mlabNsUrl, true
  #   xhr.send()

  #   xhr.onreadystatechange = ->
  #     if xhr.readyState == 4
  #       if xhr.status == 200
  #         ndtServer = JSON.parse(xhr.responseText).fqdn
  #         ndtServerIp = JSON.parse(xhr.responseText).ip

  #         console.log 'Using M-Lab Server ' + ndtServer
  #         document.getElementById('submission_hostname').value = ndtServer;

  #         # Track NDT server used
  #         Sentry.setExtra("mlab_server", ndtServer)
  #       else
  #         console.log 'M-Lab NS lookup failed.'

  #         # Track NDT server used
  #         Sentry.setExtra("mlab_server", 'failed')
  #     return
  #   return

  # getNdtServer()

  NDT_meter = new NDTmeter('#ndt-svg')
  $('#start_ndt_test').on 'click', ->
    # Note: rates are in kbits/s, latency is in milliseconds.
    s2cRate = undefined
    c2sRate = undefined
    minRTT = undefined
    NDT_meter.onstart()
    ndt7.test {
      userAcceptedDataPolicy: true
      downloadworkerfile: '/assets/js/ndt7-download-worker.min.js'
      uploadworkerfile: '/assets/js/ndt7-upload-worker.min.js'
    }, {
      serverChosen: (server) ->
        console.log 'Using M-Lab Server ', {
          machine: server.machine
          locations: server.location
        }
        document.getElementById('submission_hostname').value = server.machine
        Sentry.setExtra("mlab_server", server.machine)
        NDT_meter.onstatechange('running_s2c')
        return
      downloadMeasurement: (data) ->
        if data.Source == 'client'
          NDT_meter.onprogress('interval_s2c', {
            s2cRate: data.Data.MeanClientMbps * 1000
          })
          console.log 'Download: ' + data.Data.MeanClientMbps + ' Mb/s'
        return
      downloadComplete: (data) ->
        s2cRate = data.LastClientMeasurement.MeanClientMbps * 1000
        minRTT = (data.LastServerMeasurement.TCPInfo.MinRTT / 1000).toFixed(0)
        NDT_meter.onstatechange('finished_s2c')
        console.log('Download complete: ' + s2cRate.toFixed(2) + ' bps')
        NDT_meter.onstatechange('running_c2s')
        return
      uploadMeasurement: (data) ->
        if data.Source == 'server'
          NDT_meter.onprogress('interval_c2s', {
            c2sRate: (data.Data.TCPInfo.BytesReceived / data.Data.TCPInfo.ElapsedTime * 8) * 1000
          })
        return
      uploadComplete: (data) ->
        c2sRate = (data.LastServerMeasurement.TCPInfo.BytesReceived /
            data.LastServerMeasurement.TCPInfo.ElapsedTime * 8) * 1000
        console.log('Upload complete: ' + c2sRate.toFixed(2) + ' bps')
        NDT_meter.onfinish({
          s2cRate: s2cRate,
          c2sRate: c2sRate,
          MinRTT: minRTT
        })
        return
      error: (error) ->
        console.log 'Error: ' + error
        NDT_meter.onerror(error)
        return
    }
    return

(($) ->
  window.NdtSpeedTest || (window.NdtSpeedTest = {})

  NdtSpeedTest.init = ->
    init_controls()

  init_controls = ->
    bind_ndt_speed_calculation()
).call(this)
