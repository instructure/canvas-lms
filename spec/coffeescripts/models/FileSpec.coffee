define [
  'compiled/models/File'
  'Backbone'
], (File, {Model}) ->

  server = null
  model = null

  module 'Progress',
    setup: ->
      server = sinon.fakeServer.create()
      $el = $('<input type="file">')
      model = new File(null, preflightUrl: '/preflight')
      model.set file: $el[0]

    teardown: ->
      server.restore()

  test 'hits the preflight and then does a saveFrd', ->
    server.respondWith("POST", "/preflight", [200, {"Content-Type": "application/json"}, '{"upload_params": {}, "file_param": "file", "upload_url": "/upload"}'])
    # can't fake the upload with the server, since it's a hidden iframe post, not XHR
    stub = sinon.stub Model.prototype, 'save'
    model.save()
    ok !stub.called
    server.respond()
    ok stub.called
    stub.restore()

  test 'returns a useful deferred', ->
    server.respondWith("POST", "/preflight", [500, {}, ""])

    dfrd = model.save()
    equal dfrd.state(), "pending"
    server.respond()
    equal dfrd.state(), "rejected"




