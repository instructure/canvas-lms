define [
  'compiled/views/profiles/AvatarDialogView'
], (AvatarDialogView) ->

  module 'AvatarDialogView#onPreflight',
    setup: ->
      @avatarDialogView = new AvatarDialogView()
    teardown: ->
      @avatarDialogView = null

  test 'calls flashError with base error message when errors are present', ->
    errorMessage = "User storage quota exceeded"
    @stub(@avatarDialogView, 'enableSelectButton')
    flashError = @mock(jQuery)
    flashError.expects('flashError').withArgs(errorMessage)
    @avatarDialogView.onPreflight({}, ['{"errors":{"base":"User storage quota exceeded"}}'])
