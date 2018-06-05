#= require social-share-button

set_share_buttons = ->
  $('.social-share-button-twitter').html($('#twitter-img'))
  $('.social-share-button-facebook').html($('#facebook-img'))
  $('.social-share-button-linkedin').html($('#linkedin-img'))

bind_social_sharing = ->
  $('.social-share-btn').on 'click', ->
    $('#'+$(this).data('share')).click()

$ ->
  set_share_buttons()
  bind_social_sharing()
