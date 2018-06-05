handle_back_page_loading = ->
  count = 0

  window.onload = ->
    if typeof history.pushState == 'function'
      history.pushState 'back', null, null

      window.onpopstate = ->
        history.pushState 'back', null, null
        if count == 1
          return false

  setTimeout (->
    count = 1
    return
  ), 200

(($) ->
  window.BrowserBackDisable || (window.BrowserBackDisable = {})

  BrowserBackDisable.init = ->
    init_controls()

  init_controls = ->
    handle_back_page_loading()
).call(this)
