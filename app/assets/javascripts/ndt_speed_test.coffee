bind_ndt_speed_calculation = ->

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
      
      downloadMeasurement: (data) ->
        if data.Source == 'client'
          NDT_meter.onprogress('interval_s2c', {
            s2cRate: data.Data.MeanClientMbps * 1000
          })
      
      downloadComplete: (data) ->
        s2cRate = data.LastClientMeasurement.MeanClientMbps * 1000
        minRTT = (data.LastServerMeasurement.TCPInfo.MinRTT / 1000).toFixed(0)
        NDT_meter.onstatechange('finished_s2c')
        console.log('Download complete: ' + s2cRate.toFixed(2) + ' Kb/s')
        NDT_meter.onstatechange('running_c2s')
      
      uploadMeasurement: (data) ->
        if data.Source == 'server'
          NDT_meter.onprogress('interval_c2s', {
            c2sRate: (data.Data.TCPInfo.BytesReceived / data.Data.TCPInfo.ElapsedTime * 8) * 1000
          })
      
      uploadComplete: (data) ->
        c2sRate = (data.LastServerMeasurement.TCPInfo.BytesReceived /
            data.LastServerMeasurement.TCPInfo.ElapsedTime * 8) * 1000
        console.log('Upload complete: ' + c2sRate.toFixed(2) + ' Kb/s')
        NDT_meter.onfinish({
          s2cRate: s2cRate,
          c2sRate: c2sRate,
          MinRTT: minRTT
        })
        NDT_meter.onstatechange('finished_all')
      
      error: (error) ->
        console.log 'Error: ' + error
        NDT_meter.onerror(error)
    }

(($) ->
  window.NdtSpeedTest || (window.NdtSpeedTest = {})

  NdtSpeedTest.init = ->
    init_controls()

  init_controls = ->
    bind_ndt_speed_calculation()
).call(this)
