jQuery.loadScript = (url, callback) ->
  jQuery.ajax
    url: url
    dataType: 'script'
    success: callback
    async: true

draw_residential_speed_chart = ->
  $.ajax
    url: '/speed_data'
    type: 'GET'
    dataType: 'json'
    data:
      provider: 'all'
      categories: ['0..5.99', '6..25.99', '26..50.99', '51..100.99', '101..200.99', '201..500', '500+']
      connection_type: 'Home Wifi'
    success: (data) ->
      colors = ['#93CDDD']
      draw_bar_chart('all_residential_speed_chart', data.categories, data.values, colors, true)
      bind_home_speed_comparison_values(data.values)

bind_home_speed_comparison_values = (values) ->
  $('.home-speed-0-to-5').text("#{Math.round(values[0])}%")
  $('.home-speed-6-to-25').text("#{Math.round(values[0] + values[1])}%")
  $('.home-speed-101-to-200').text("#{Math.round(values[4] + values[5] + values[6])}%")
  $('.home-speed-201-to-500').text("#{Math.round(values[5] + values[6])}%")

draw_isps_home_internet_chart = ->
  $.ajax
    url: '/isps_data'
    type: 'GET'
    dataType: 'json'
    data:
      type: 'isps_usage'
      provider: 'all'
      categories: ['Comcast xfinity', 'ATT', 'Other']
      connection_type: 'Home Wifi'
    success: (data) ->
      colors = ['#4C82C2', '#E0502E', '#545151']
      legend_vals = {
        verticalAlign: 'top'
      }
      draw_pie_chart('home_internet_isps_chart', data['usage_percentages'], colors, legend_vals, '%', 2, '#ffffff')

draw_att_residential_speeds_chart = ->
  $.ajax
    url: '/speed_data'
    type: 'GET'
    dataType: 'json'
    data:
      provider: 'ATT'
      categories: ['0..5.99', '6..25.99', '26..50.99', '51..100.99', '101..200.99', '201..500', '500+']
      connection_type: 'Home Wifi'
    success: (data) ->
      colors = ['#FD8C30']
      draw_bar_chart('att_residential_speeds_chart', data.categories, data.values, colors, false)

draw_comcast_residential_speeds_chart = ->
  $.ajax
    url: '/speed_data'
    type: 'GET'
    dataType: 'json'
    data:
      provider: 'Comcast xfinity'
      categories: ['0..5.99', '6..25.99', '26..50.99', '51..100.99', '101..200.99', '201..500', '500+']
      connection_type: 'Home Wifi'
    success: (data) ->
      colors = ['#4C82C2']
      draw_bar_chart('comcast_residential_speeds_chart', data.categories, data.values, colors, false)

draw_att_satisfaction_rating_chart = ->
  $.ajax
    url: '/isps_data'
    type: 'GET'
    dataType: 'json'
    data:
      type: 'isps_satisfactions'
      provider: 'ATT'
      categories: ['Negative', 'Neutral', 'Positive']
      connection_type: 'Home Wifi'
    success: (data) ->
      colors = ['#C00000', '#FFFF66', '#00B050']
      legend_vals = {
        verticalAlign: 'top'
      }
      draw_pie_chart('att_satisfaction_chart', data, colors, legend_vals, '%', 2)

draw_comcast_satisfaction_rating_chart = ->
  $.ajax
    url: '/isps_data'
    type: 'GET'
    dataType: 'json'
    data:
      type: 'isps_satisfactions'
      provider: 'Comcast xfinity'
      categories: ['Negative', 'Neutral', 'Positive']
      connection_type: 'Home Wifi'
    success: (data) ->
      colors = ['#C00000', '#FFFF66', '#00B050']
      legend_vals = {
        verticalAlign: 'top'
      }
      draw_pie_chart('comcast_satisfaction_chart', data, colors, legend_vals, '%', 2)

draw_isps_mobile_internet_chart = ->
  $.ajax
    url: '/isps_data'
    type: 'GET'
    dataType: 'json'
    data:
      type: 'isps_usage'
      provider: 'all'
      categories: ['ATT', 'Boost Mobile', 'Cricket Wireless', 'Sprint', 'T-Mobile', 'Verizon', 'Other']
      connection_type: 'Mobile Data'
    success: (data) ->
      colors = ['#F79646', '#8C2825', '#6B892F', '#FF0000', '#FF6699', '#FFFF00', '#593F7A']
      legend_vals = {
        verticalAlign: 'bottom'
        itemMarginTop: 5
        itemMarginBottom: 5
      }
      draw_pie_chart('mobile_internet_isps_chart', data['usage_percentages'], colors, legend_vals, '%', 0)

draw_mobile_isps_avg_speed_chart = ->
  $.ajax
    url: '/isps_data'
    type: 'GET'
    dataType: 'json'
    data:
      type: 'mobile_isps_speeds'
      provider: 'multiple'
      categories: ['Sprint', 'Verizon', 'T-Mobile', 'ATT']
      connection_type: 'Mobile Data'
    success: (data) ->
      colors = ['#FFFF00', '#FF0000', '#FF6699', '#F79646']
      draw_bar_chart('mobile_isps_average_speed_chart', data.categories, data.values, colors, true, '')

draw_mobile_isps_satisfaction_chart = ->
  $.ajax
    url: '/isps_data'
    type: 'GET'
    dataType: 'json'
    data:
      type: 'mobile_isps_satisfactions'
      provider: 'multiple'
      categories: ['Sprint', 'Verizon', 'T-Mobile', 'ATT']
      connection_type: 'Mobile Data'
    success: (data) ->
      colors = ['#FFFF00', '#FF0000', '#FF6699', '#F79646']
      draw_bar_chart('mobile_provider_safisfaction_chart', data.categories, data.values, colors, true, '')

draw_public_satisfaction_ratings_chart = ->
  $.ajax
    url: '/isps_data'
    type: 'GET'
    dataType: 'json'
    data:
      type: 'isps_satisfactions'
      provider: 'all'
      categories: ['Negative', 'Neutral', 'Positive']
      connection_type: 'Public Wifi'
    success: (data) ->
      colors = ['#C00000', '#FFFF66', '#00B050']
      legend_vals = {
        verticalAlign: 'top'
      }
      draw_pie_chart('public_internet_isps_chart', data, colors, legend_vals, '%', 2)

draw_public_download_speeds_chart = ->
  $.ajax
    url: '/speed_data'
    type: 'GET'
    dataType: 'json'
    data:
      provider: 'all'
      categories: ['0..5.99', '6..25.99', '26..50.99', '51..100.99', '101..200.99', '201..500', '500+']
      connection_type: 'Public Wifi'
    success: (data) ->
      colors = ['#4c82C2']
      draw_bar_chart('public_download_speeds_chart', data.categories, data.values, colors, true)

draw_bar_chart = (id, categories, values, colors, yAxis_labels, valye_type='%') ->
  $("##{id}").highcharts
    chart: type: 'bar'
    legend: enabled: false
    colors: colors
    title: text: ''
    xAxis:
      categories: categories
      title: text: null
    yAxis:
      min: 0
      title:
        text: ''
        align: 'high'
      labels:
        enabled: yAxis_labels
        overflow: 'justify'
        formatter: ->
          @value + " #{valye_type}"
    tooltip: valueSuffix: " #{valye_type}"
    plotOptions: bar: dataLabels: enabled: true
    credits: enabled: false
    series: [
      {
        name: 'Value'
        colorByPoint: true
        data: values
        dataLabels:
          enabled: true
          color: '#000000'
          align: 'right'
          format: "{point.y:.2f}#{valye_type}"
          style:
            fontSize: '13px'
            fontFamily: 'Verdana, sans-serif'
      }
    ]

draw_pie_chart = (id, data, colors, legend_vals, value_type, decimals, label_color='#000000') ->
  Highcharts.setOptions colors: colors
  $("##{id}").highcharts
    chart:
      plotBackgroundColor: null
      plotBorderWidth: null
      plotShadow: false
      type: 'pie'
    title: text: ''
    tooltip: pointFormat: '{series.name}: <b>{point.percentage:.2f}%</b>'
    plotOptions: pie:
      allowPointSelect: true
      cursor: 'pointer'
      dataLabels:
        enabled: true
        color: label_color
        distance: -40
        format: "{point.percentage:.#{decimals}f}#{value_type}"
        style: textShadow: false
      showInLegend: true
    credits: enabled: false
    legend: legend_vals
    series: [ {
      name: 'ISP'
      colorByPoint: true
      data: data
    } ]

$ ->
  if window.location.pathname.indexOf('result') >= 0
    $.loadScript 'https://code.highcharts.com/highcharts.js', ->
      draw_residential_speed_chart()
      draw_isps_home_internet_chart()
      draw_att_residential_speeds_chart()
      draw_comcast_residential_speeds_chart()
      draw_att_satisfaction_rating_chart()
      draw_comcast_satisfaction_rating_chart()
      draw_isps_mobile_internet_chart()
      draw_mobile_isps_avg_speed_chart()
      draw_mobile_isps_satisfaction_chart()
      draw_public_satisfaction_ratings_chart()
      draw_public_download_speeds_chart()
