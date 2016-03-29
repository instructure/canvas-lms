define [
  'jquery'
  'Backbone'
], ($, Backbone) ->

  class DiscussionTopicToolbarView extends Backbone.View

    events:
      'focus #keyboard-shortcut-modal-info' : 'showKeyboardShortcutModalInfo'
      'blur #keyboard-shortcut-modal-info' : 'hideKeyboardShortcutModalInfo'

    showKeyboardShortcutModalInfo: (e) ->
      $(e.currentTarget).children('.accessibility-warning').show()

    hideKeyboardShortcutModalInfo: (e) ->
      $(e.currentTarget).children('.accessibility-warning').hide()
