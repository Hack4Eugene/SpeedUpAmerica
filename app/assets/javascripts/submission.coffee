bind_rating_stars = ->
  star_options =
    stars: 7
    min: 0
    max: 7
    step: 0.5
    displayOnly: true
    showClear: false
    showCaption: false
    size:'sm'

  $('.average_rating').rating star_options

$ ->
  bind_rating_stars()
