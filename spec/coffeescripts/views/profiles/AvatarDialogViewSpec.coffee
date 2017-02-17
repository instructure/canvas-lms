define [
  'jquery'
  'compiled/views/profiles/AvatarDialogView'
], ($, AvatarDialogView) ->

  QUnit.module 'AvatarDialogView#onPreflight',
    setup: ->
      @avatarDialogView = new AvatarDialogView()
    teardown: ->
      @avatarDialogView = null

  test 'calls flashError with base error message when errors are present', ->
    errorMessage = "User storage quota exceeded"
    @stub(@avatarDialogView, 'enableSelectButton')
    mock = @mock($).expects('flashError').withArgs(errorMessage)
    @avatarDialogView.onPreflight({}, [{responseText:'{"errors":{"base":[{"message":"User storage quota exceeded"}]}}'}])
    ok(mock.verify())

  QUnit.module 'AvatarDialogView#postAvatar',
    setup: ->
      @avatarDialogView = new AvatarDialogView()
    teardown: ->
      @avatarDialogView = null

  test 'calls flashError with base error message when errors are present', ->
    errorMessage = "User storage quota exceeded"
    preflightResponse = {
      upload_url: 'http://some_url',
      upload_params: {},
      file_param: ''
    }
    fakeXhr = {
      responseText: '{"errors":{"base":[{"message":"User storage quota exceeded"}]}}'
    }
    @stub($, 'ajax').yieldsTo('error', fakeXhr)
    mock = @mock($).expects('flashError').withArgs(errorMessage)
    @avatarDialogView.postAvatar(preflightResponse)
    ok(mock.verify())
