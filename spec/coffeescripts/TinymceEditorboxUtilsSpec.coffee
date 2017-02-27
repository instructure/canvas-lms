define ['tinymce.editor_box_utils'], (Utils)->
  QUnit.module "Tinymce Utils #cleanUrl", ->
    setup: ->
    teardown: ->

  test "it doesnt hurt a good url", ->
    url = "http://www.google.com"
    output = Utils.cleanUrl(url)
    equal(output, url)

  test "it turns email addresses into mailto links", ->
    output = Utils.cleanUrl("ethan@instructure.com")
    equal(output, "mailto:ethan@instructure.com")

  test "adding a protocol to unprotocoled addresses", ->
    input = "www.example.com"
    output = Utils.cleanUrl(input)
    equal(output, "http://#{input}")

  test "doesnt mailto links with @ in them", ->
    input = "https://www.google.com/maps/place/331+E+Winchester+St,+Murray,+UT+84107/@40.633021,-111.880836,17z/data=!3m1!4b1!4m2!3m1!1s0x875289b8a03ae74d:0x2e83de307059e47d"
    output = Utils.cleanUrl(input)
    equal(output, input)
