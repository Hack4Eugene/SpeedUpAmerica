speed_breakdown_by_isp_chart = (data) ->
  $('#speed_breakdown_by_isp').highcharts
    chart: type: 'areaspline'
    legend:
      align: 'center'
      verticalAlign: 'top'
      layout: 'horizontal'
    title: text: ''
    xAxis:
      categories: data.categories
      title: text: null
    yAxis:
      min: 0
      title:
        text: ''
        align: 'high'
      labels:
        enabled: true
        overflow: 'justify'
        formatter: ->
          @value + " %"
    tooltip: valueSuffix: " %"
    colors: ['#FF00FF', '#9A7A53', '#D7A069', '#526D7A', '#8CABEC', '#FF3232', '#0A6F42']
    plotOptions: bar:
      dataLabels: enabled: true
      column: colorByPoint: true
    credits: enabled: false
    series: data.series

median_speed_by_isp_chart = (data) ->
  $('#median_speed_by_isp_chart').highcharts
    chart: type: 'spline'
    credits: enabled: false
    title: text: ''
    legend:
      align: 'center'
      verticalAlign: 'top'
      layout: 'horizontal'
    xAxis: categories: data.categories
    yAxis:
      title: text: 'Internet Speed (Mbps)'
    colors: ['#FF00FF', '#9A7A53', '#D7A069', '#526D7A', '#8CABEC', '#FF3232', '#0A6F42']
    plotOptions: line:
      dataLabels: enabled: false
      enableMouseTracking: false
      column: colorByPoint: true
    series: data.series

tests_per_isp_chart = (data) ->
  $('#tests_per_isp_chart').highcharts
    chart: events: load: ->
      $('.stats-section').removeClass('blurred')
      $('#stats_loader').addClass('hide')
    type: 'column'
    credits: enabled: false
    title: text: ''
    xAxis: categories: data.categories
    yAxis:
      min: 0
      title: text: 'Number of Tests'
      stackLabels:
        enabled: false
    legend:
      align: 'center'
      verticalAlign: 'top'
      layout: 'horizontal'
    colors: ['#FF00FF', '#9A7A53', '#D7A069', '#526D7A', '#8CABEC', '#FF3232', '#0A6F42']
    plotOptions: column:
      stacking: 'normal'
      dataLabels:
        enabled: false
      column: colorByPoint: true
    series: data.series

window.draw_stats_charts = (statistics, filter) ->
  statistics.zip_code = [ZIP_CODE]
  disable_filters('stats_filters', true)
  $.ajax
    url: '/speed_data'
    type: 'GET'
    dataType: 'json'
    data:
      statistics: statistics
    success: (data) ->
      if Object.keys(data).length > 0
        bind_home_speed_comparison_values(data.speed_comparison_data)
        speed_breakdown_by_isp_chart(data.speed_breakdown_chart_data)
        median_speed_by_isp_chart(data.median_speed_chart_data)
        tests_per_isp_chart(data.tests_count_data)
        $('.total-tests').text(data.total_tests)
        disable_filters('stats_filters', false)
      else
        $('.stats-section').removeClass('blurred')
        $('#stats_loader').addClass('hide')
        disable_filters('stats_filters', true)
    error: (request, statusText, errorText) ->
      err = new Error("get speed data failed")

      Sentry.setExtra("status_code", request.status)
      Sentry.setExtra("body",  request.responseText)
      Sentry.setExtra("response_status",  statusText)
      Sentry.setExtra("response_error",  errorText)
      Sentry.captureException(err)

average = (data) ->
  data.reduce(((p, c, i, a) ->
    p + c / a.length
  ), 0)

bind_home_speed_comparison_values = (values) ->
  $('.home-speed-0-to-5').text("#{values.less_than_5.toFixed(2)}%")
  $('.home-speed-6-to-25').text("#{values.less_than_25.toFixed(2)}%")
  $('.home-speed-101-to-200').text("#{values.faster_than_100.toFixed(2)}%")
  $('.home-speed-201-to-500').text("#{values.faster_than_250.toFixed(2)}%")
  $('.speedup-tests-count').text(values.speedup_tests_count)
  $('.mlab-tests-count').text(values.mlab_tests_count)
