define [
  'jquery'
  'compiled/jquery/mediaComment'
], ($, MediaUtils)->

  module 'mediaComment',
    setup: ->
      @server = sinon.fakeServer.create()
      window.INST.kalturaSettings = "settings set" # pretend kalturaSettings are set.
      @$holder = $('<div id="media-holder">').appendTo('#fixtures')

    teardown: ->
      window.INST.kalturaSettings = null
      @server.restore()
      @$holder.remove()

  mockServerResponse = (server, id, type="video") =>
    resp = {
      media_sources: [
        {"content_type": "flv", "url": "http://some_flash_url.com"},
        {"content_type": "mp4", "url": "http://some_mp4_url.com"}
      ]
    }

    server.respond 'GET', "/media_objects/#{id}/info", [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(resp)
    ]

  test "video player is displayed inline", ->
    id = 10 #ID doesn't matter since we mock out the server
    @$holder.mediaComment('show_inline', id)
    mockServerResponse(@server, id)

    video_tag_exists = @$holder.find('video').length is 1
    ok video_tag_exists, 'There should be a video tag'

  test "audio player is displayed correctly", ->
    id = 10 #ID doesn't matter since we mock out the server
    @$holder.mediaComment('show_inline', id, 'audio')
    mockServerResponse(@server, id, 'audio')

    equal @$holder.find('audio').length, 1, 'There should be a audio tag'
    equal @$holder.find('video').length, 0, 'There should not be a video tag'


  test "video player includes url sources provided by the server", ->
    id = 10 #ID doesn't matter since we mock out the server
    @$holder.mediaComment('show_inline', id)
    mockServerResponse(@server, id)

    equal @$holder.find('source[type=flv]').attr('src'),"http://some_flash_url.com", "Video contains the flash source"
    equal @$holder.find('source[type=mp4]').attr('src'),"http://some_mp4_url.com", "Video contains the mp4 source"


  module "MediaCommentUtils functions",
    setup: ->
    teardown: ->

  test "getElement includes width and height for video elements", ->
    $media = MediaUtils.getElement("video", "", 100, 200)
    equal($media.attr("width"), 100)
    equal($media.attr("height"), 200)

  test "getElement doesnt care about width and height for audio elements", ->
    $media = MediaUtils.getElement("audio", "", 100, 200)
    equal($media.attr("width"), null)
    equal($media.attr("height"), null)

  test "getElement adds preload='metadata' to both types", ->
    $video = MediaUtils.getElement("video", "", 100, 200)
    $audio = MediaUtils.getElement("audio", "", 100, 200)
    equal($video.attr("preload"), "metadata")
    equal($audio.attr("preload"), "metadata")

  test "getElement puts source tags inside the element", ->
    st_tag = "<source src='something'></source>"
    $audio = MediaUtils.getElement("audio", st_tag)
    equal($audio.html(), "<source src=\"something\">")
