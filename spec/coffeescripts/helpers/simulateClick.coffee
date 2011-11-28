define "helpers/simulateClick", [ "vendor/jquery-1.6.4" ], (_) ->
  (element) ->
    unless document.createEvent
      element.click()
      return
    e = document.createEvent("MouseEvents")
    e.initEvent "click", true, true
    element.dispatchEvent e