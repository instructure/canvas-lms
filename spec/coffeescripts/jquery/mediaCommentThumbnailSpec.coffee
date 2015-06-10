define [
  'jquery'
  'underscore'
  'compiled/jquery/mediaCommentThumbnail'
], ($, _)->
  # fragile spec

  module 'mediaCommentThumbnail',
    setup: ->
      # flop out the _.defer function to just call directly down to the passed
      # function reference. this helps the tests run in a synchronous order
      # internally so asserts can work like we expect.
      @stub = sinon.stub _, 'defer', (func, args...) ->
        func(args...)
      @$fixtures = $('#fixtures')

    teardown: ->
      _.defer.restore()
      window.INST.kalturaSettings = null

  test "creates a thumbnail span with a background image URL generated from kaltura settings and media id", ->
    resourceDomain = 'resources.example.com'
    mediaId        = 'someExternalId'
    partnerId      = '12345'
    mediaComment   = $("""
      <a id="media_comment_#{mediaId}" class="instructure_inline_media_comment video_comment" href="/media_objects/#{mediaId}">
        this is a media comment
      </a>
      """)
    window.INST.kalturaSettings = {
      resource_domain: resourceDomain
      partner_id:      partnerId
    }
    @$fixtures.append mediaComment

    # emulating the call from enhanceUserContent() in instructure.js
    $('.instructure_inline_media_comment', @$fixtures).mediaCommentThumbnail('normal')

    equal $('.media_comment_thumbnail', @$fixtures).length, 1
    ok $('.media_comment_thumbnail', @$fixtures).first().css('background-image').indexOf("https://#{resourceDomain}/p/#{partnerId}/thumbnail/entry_id/#{mediaId}/width/140/height/100/bgcolor/000000/type/2/vid_sec/5") > 0
