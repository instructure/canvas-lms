require [
  'jquery'
  'compiled/jquery/mediaComment'
], ($)->
  module 'mediaComment',
    setup: -> 
      @server = sinon.fakeServer.create()
      window.INST.kalturaSettings = "settings set" # pretend kalturaSettings are set.
      @$video = $('<div id="video">')
      $('#fixtures').append @$video

    teardown: -> 
      window.INST.kalturaSettings = null 
      @server.restore()
      @$video.remove()

  mockServerResponse = (server, id) => 
    server.respond 'GET', "/media_objects/#{id}/info", [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(
      {
        "media_sources": 
                [
                  {"content_type": "flv", "url": "http://some_flash_url.com"}
                  {"content_type": "mp4", "url": "http://some_mp4_url.com"}
                ]
      })]

  test "video player is displayed inline", -> 
    id = 10 #ID doesn't matter since we mock out the server
    @$video.mediaComment('show_inline', id)
    mockServerResponse(@server, id)

    video_tag_exists = @$video.find('video').length is 1
    ok video_tag_exists, 'There should be a video tag'

  test "video player includes url sources provided by the server", -> 
    id = 10 #ID doesn't matter since we mock out the server
    @$video.mediaComment('show_inline', id)
    mockServerResponse(@server, id)

    equal @$video.find('source[type=flv]').attr('src'),"http://some_flash_url.com", "Video contains the flash source"
    equal @$video.find('source[type=mp4]').attr('src'),"http://some_mp4_url.com", "Video contains the mp4 source"


