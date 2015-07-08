define [
  'compiled/views/profiles/AvatarDialogView'
], (AvatarDialogView) ->

  module 'AvatarDialogView#onPreflight',
    setup: ->
      @avatarDialogView = new AvatarDialogView()
    teardown: ->
      @avatarDialogView = null

  test 'calls flashError with base error message when errors are present', ->
    errorMessage = "this is an error message"
    aDV = sinon.stub(@avatarDialogView, 'enableSelectButton')
    flashError = sinon.mock(jQuery)
    @avatarDialogView.onPreflight({}, ['{"errors":{"base":"User storage quota exceeded"}}'])
    ok flashError.expects('flashError').withArgs(errorMessage), 'calls a flash error with response error message'
    flashError.restore()
    aDV.restore()

