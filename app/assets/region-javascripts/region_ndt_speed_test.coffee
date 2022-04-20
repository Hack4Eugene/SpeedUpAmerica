region_bind_ndt_speed_calculation = ->
  RegionNDT_meter = new NDTmeter('#ndt-svg')
  console.log('region_bind_ndt_speed_calculation');
  $('#region_start_ndt_test').on 'click', ->
    # Note: rates are in kbits/s, latency is in milliseconds.
    s2cRate = undefined
    c2sRate = undefined
    minRTT = undefined
    RegionNDT_meter.onstart()
    ndt7.test({
      userAcceptedDataPolicy: true
      downloadworkerfile: '/assets/js/ndt7-download-worker.min.js'
      uploadworkerfile: '/assets/js/ndt7-upload-worker.min.js'
    }, {
      serverChosen: (server) ->
        console.log 'Using M-Lab Server ', {
          machine: server.machine
          locations: server.location
        }
#       document.getElementById('submission_hostname').value = server.machine
        Sentry.setExtra("mlab_server", server.machine)
        RegionNDT_meter.onstatechange('running_s2c')

      downloadMeasurement: (data) ->
        if data.Source == 'client'
          RegionNDT_meter.onprogress('interval_s2c', {
            s2cRate: data.Data.MeanClientMbps * 1000
          })

      downloadComplete: (data) ->
        s2cRate = data.LastClientMeasurement.MeanClientMbps * 1000
        minRTT = (data.LastServerMeasurement.TCPInfo.MinRTT / 1000).toFixed(0)
        RegionNDT_meter.onstatechange('finished_s2c')
        console.log('Regional Download complete: ' + s2cRate.toFixed(2) + ' Kb/s')
        RegionNDT_meter.onstatechange('running_c2s')

      uploadMeasurement: (data) ->
        if data.Source == 'server'
          RegionNDT_meter.onprogress('interval_c2s', {
            c2sRate: (data.Data.TCPInfo.BytesReceived / data.Data.TCPInfo.ElapsedTime * 8) * 1000
          })

      uploadComplete: (data) ->
        c2sRate = (data.LastServerMeasurement.TCPInfo.BytesReceived /
            data.LastServerMeasurement.TCPInfo.ElapsedTime * 8) * 1000
        console.log('Regional Upload complete: ' + c2sRate.toFixed(2) + ' Kb/s')
        RegionNDT_meter.onfinish({
          s2cRate: s2cRate,
          c2sRate: c2sRate,
          MinRTT: minRTT
        })
        RegionNDT_meter.onstatechange('finished_all')

      error: (error) ->
        console.log 'Error: ' + error
        RegionNDT_meter.onerror(error)
    })

(($) ->
  window.NdtSpeedTest || (window.NdtSpeedTest = {})

 NdtSpeedTest.init = ->
    console.log('RegionNdtSpeedTest.init 1');
    region_bind_ndt_speed_calculation()
).call(this)
