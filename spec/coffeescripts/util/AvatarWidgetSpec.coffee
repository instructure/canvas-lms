define ['jquery', 'compiled/util/AvatarWidget'], ($, AvatarWidget)->

  QUnit.module 'AvatarWidget',
    setup: ->
    teardown: ->
      $(".avatar-nav").remove()
      $(".ui-dialog").remove()
      $("#fixtures").empty()

  test 'opens dialog on element click', ->
    targetElement = $("<a href='#' id='avatar-opener'>Click</a>")
    $("#fixtures").append(targetElement)
    wrappedElement = $("a#avatar-opener")
    widget = new AvatarWidget(wrappedElement)
    wrappedElement.click()
    ok($(".avatar-nav").length > 0)
