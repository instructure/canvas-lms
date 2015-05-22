define [ "jquery" ], (jQuery) ->
  $fixtures = jQuery("#fixtures")
  fixtures = {}
  fixtureId = 1
  (fixture) ->
    id = fixture + fixtureId++
    path = "fixtures/" + fixture + ".html"
    jQuery.ajax
      async: false
      cache: false
      dataType: "html"
      url: path
      success: (html) ->
        fixtures[id] = jQuery("<div/>",
          html: html
          id: id
        ).appendTo($fixtures)

      error: ->
        console.error "Failed to load fixture", path

    fixtures[id]
