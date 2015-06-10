define [
  'compiled/models/Entry'
  'helpers/fakeENV'
], (Entry, fakeENV) ->

  module 'Entry',
    setup: ->
      fakeENV.setup()
      @user_id = 1
      @server = sinon.fakeServer.create()
      ENV.DISCUSSION = {
        CURRENT_USER:
          id: @user_id
        DELETE_URL: 'discussions/:id/'
        PERMISSIONS:
          CAN_ATTACH: true
          CAN_MANAGE_OWN: true
      }
      @entry = new Entry(id: 1, message: 'a comment, wooper', user_id: @user_id)

    teardown: ->
      fakeENV.teardown()
      @server.restore()

  # sync
  test 'should persist replies locally, and call provided onComplete callback', ->
    @server.respondWith([200, {}, ''])
    replies = [new Entry(id: 2, message: 'a reply', parent_id: 1)]
    @entry.set('replies', replies)
    @setSpy = sinon.spy(@entry, 'set')
    onCompleteCallback = sinon.spy()

    @entry.sync('update', @entry, {
      complete: onCompleteCallback
    })
    @server.respond()

    ok @setSpy.calledWith('replies', [])
    ok @setSpy.calledWith('replies', replies)
    ok onCompleteCallback.called
