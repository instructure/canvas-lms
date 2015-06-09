define [
  'jquery'
  'underscore'
  'compiled/behaviors/instructure_inline_media_comment'
], ($, _, inlineMediaComment) ->

  oldTrackEvent = null

  module 'inlineMediaComment',
    setup: ->
      oldTrackEvent = $.trackEvent
      @fixtures = document.getElementById('fixtures')
      @fixtures.innerHTML = "<a data-media_comment_id=42 class='instructure_inline_media_comment' href='42' tabindex=0></a>"
      window.INST.kalturaSettings = "settings set"
    teardown: ->
      $.trackEvent = oldTrackEvent
      @fixtures.innerHTML = ""
      window.INST.kalturaSettings = null

  test 'anchor tag with proper class triggers media load when clicked', ->
    $.trackEvent = (()-> null)
    $link = $(@fixtures).find('a')
    $link.click()
    ok($link.next().html().match(/Loading media/))

  test "buildMinimizerLink generates a destinationless a tag", ->
    link = inlineMediaComment.buildMinimizerLink()
    ok(link.is("a"))
    equal(link.attr('href'), "#")

  test "buildHolder contains a tabindex for better tab navigation", ->
    holder = inlineMediaComment.buildCommentHolder()
    ok(holder.html().match(/tabindex="0"/))

  test "getMediaCommentId pulls straight from data element", ->
    $link = $("<a data-media_comment_id='42'></a>")
    id = inlineMediaComment.getMediaCommentId($link)
    equal("42", id)

  test "getMediaCommentId can pull from an inner element in an html block", ->
    $link = $("<a><span class='media_comment_id'>24</span></a>")
    id = inlineMediaComment.getMediaCommentId($link)
    equal("24", id)
