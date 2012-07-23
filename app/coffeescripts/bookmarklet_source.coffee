canvasDomain = 'put_canvas_domain_here'

# matches '//foo.bar/' in 'http://foo.bar/baz.js'
reDomainWithSlashes = /\/\/\S*\//

getSelection = ->
  selection = if window.getSelection
                window.getSelection()
              else if document.getSelection
                document.getSelection()
              else
                document.selection.createRange().text
  "#{selection}".replace /(^\s+|\s+$)/g, ""

pin = (urlToPin) ->
  width = 700
  height = 450
  left = Math.round((screen.width / 2) - (width / 2))
  screenHeight = screen.height
  top = if screenHeight > height
    Math.round((screenHeight / 2) - (width / 2))
  else
    0
  queryString = [
    "popup=1"
    "link_url=#{encodeURIComponent(urlToPin)}"
    "description=#{encodeURIComponent(getSelection().substr(0, 1000))}"
  ].join('&')
  popupUrl = "//#{canvasDomain}/collection_items/new/?#{queryString}"

  windowFeatures = "width=#{width},height=#{height},left=#{left},top=#{top},status=no,resizable=yes,scrollbars=yes,personalbar=no,directories=no,location=no,toolbar=no,menubar=no"
  window.open(popupUrl, "popup#{+(new Date)}", windowFeatures)

pin(window.location)
