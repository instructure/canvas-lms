define [
  'compiled/views/profiles/GravatarView'
], (GravatarView) ->

  QUnit.module 'GravatarView',
    setup: ->
      @oldEnv = window.ENV
      window.ENV = { PROFILE: { primary_email: 'foo@example.com' }}
      @view = new GravatarView(avatarSize: { h: 42, w: 42 })
      @view.$el.appendTo('#fixtures')
      @view.render()
      @view.setup()
      @$preview = @view.$el.find('.gravatar-preview-image')
      @$previewButton = @view.$el.find('.gravatar-preview-btn')
      @$input = @view.$el.find('.gravatar-preview-input')

    teardown: ->
      window.ENV = @oldEnv
      @view.remove()
      @server?.restore()

  test 'pre-populates preview with default', ->
    md5 = 'b48def645758b95537d4424c84d1a9ff'
    equal @$preview.attr('src'),
      "https://secure.gravatar.com/avatar/#{md5}?s=200&d=identicon"

  test 'updates preview', ->
    md5 = 'e8da7df89c8bcbfec59336b4e0d5e76d'
    @$input.val('bar@example.com')
    @$previewButton.click()
    equal @$preview.attr('src'),
      "https://secure.gravatar.com/avatar/#{md5}?s=200&d=identicon"

  test 'calls avatar url with specified size', ->
    @server = sinon.fakeServer.create()
    @server.respond (request) ->
      url_match = request.url.match(/api\/v1\/users\/self/)
      ok url_match, "call to unexpected url"
      body_param = encodeURIComponent("user[avatar][url]")
      body_match = request.requestBody.match(body_param)
      ok body_match, "did not specify avatar url parameter"
      size_param = encodeURIComponent("s=42")
      size_match = request.requestBody.match(size_param)
      ok size_match, "did not specify correct size"

      request.respond(200, {'Content-Type': 'application/json'}, "{}")

    @view.updateAvatar()
    @server.respond()
