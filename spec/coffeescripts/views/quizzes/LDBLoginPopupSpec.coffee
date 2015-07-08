define [
  "underscore"
  "jquery"
  "compiled/views/quizzes/LDBLoginPopup"
], (_, $, LDBLoginPopup, FormMarkup) ->
  whnd = undefined
  popup = undefined
  server = undefined
  root = this
  module "LDBLoginPopup",
    setup: ->
      popup = new LDBLoginPopup(sticky: false)

    teardown: ->
      if whnd and not whnd.closed
        whnd.close()
        whnd = null

      server.restore() if server

  test "it should exec", 1, ->
    whnd = popup.exec()

    ok whnd, "popup window is created"

  test "it should inject styleSheets", 1, ->
    whnd = popup.exec()

    strictEqual $(whnd.document).find("link[href]").length,
      $(root.document).find("link[href]").length

  test "it should trigger the @open and @close events", ->
    onOpen = sinon.spy()
    onClose = sinon.spy()

    popup.on "open", onOpen
    popup.on "close", onClose

    whnd = popup.exec()
    ok onOpen.called, "@open handler gets called"

    whnd.close()
    ok onClose.called, "@close handler gets called"

  test "it should close after a successful login", 1, ->
    onClose = sinon.spy()

    server = sinon.fakeServer.create()
    server.respondWith "POST", /login/, [ 200, {}, "OK" ]

    popup.on "close", onClose
    popup.on "open", (e, document) ->
      $(document).find(".btn-primary").click()
      server.respond()
      ok onClose.called, "popup should be closed"

    whnd = popup.exec()

  test "it should trigger the @login_success event", 1, ->
    onSuccess = sinon.spy()

    server = sinon.fakeServer.create()
    server.respondWith "POST", /login/, [ 200, {}, "OK" ]

    popup.on "login_success", onSuccess
    popup.on "open", (e, document) ->
      $(document).find(".btn-primary").click()
      server.respond()
      ok onSuccess.called, "@login_success handler gets called"

    whnd = popup.exec()

  test "it should trigger the @login_failure event", 1, ->
    onFailure = sinon.spy()

    server = sinon.fakeServer.create()
    server.respondWith "POST", /login/, [ 401, {}, "Bad Request" ]

    popup.on "login_failure", onFailure
    popup.on "open", (e, document) ->
      $(document).find(".btn-primary").click()
      server.respond()
      ok onFailure.called, "@login_failure handler gets called"

    whnd = popup.exec()

  asyncTest "it should pop back in if student closes it", 5, ->
    latestWindow = undefined
    onFailure = sinon.spy()
    onOpen = sinon.spy()
    onClose = sinon.spy()
    originalOpen = window.open

    # needed for proper cleanup of windows
    openStub = sinon.stub window, "open", ->
      latestWindow = originalOpen.apply(this, arguments)

    server = sinon.fakeServer.create()
    server.respondWith "POST", /login/, [ 401, {}, "Bad Request" ]

    # a sticky version
    popup = new LDBLoginPopup(sticky: true)
    popup.on "login_failure", onFailure
    popup.on "open", onOpen
    popup.on "close", onClose
    popup.one "open", (e, document) ->
      $(document).find(".btn-primary").click()
      server.respond()
      ok onFailure.calledOnce, "logged out by passing in bad credentials"

      _.defer ->
        whnd.close()

      popup.one "close", ->
        # we need to defer because #open will not be called in the close handler
        _.defer ->
          start()
          ok onOpen.calledTwice, "popup popped back in"
          ok onClose.calledOnce, "popup closed"

          # clean up the dangling window which we don't have a handle to
          popup.off "close.sticky"
          latestWindow.close()
          ok onClose.calledTwice, "popup closed for good"
          openStub.restore()

    whnd = popup.exec()
    ok onOpen.called, "popup opened"