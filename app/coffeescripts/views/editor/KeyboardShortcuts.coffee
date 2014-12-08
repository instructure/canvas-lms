define [
  'underscore'
  'i18n!editor.keyboard_shortcuts'
  'jquery'
  'Backbone'
  'jst/editor/KeyboardShortcuts'
], (_, I18n, $, Backbone, Template) ->
  ZERO_KEYCODES = [
    48 # regular 0
    96 # numpad 0
  ]

  ##
  # A dialog that lists available keybindings for TinyMCE.
  #
  # The dialog can be launched by pressing ALT+0, or by clicking a little ? icon
  # in the editor action bar.
  KeyboardShortcuts = Backbone.View.extend
    className: 'tinymce-keyboard-shortcuts-toggle'
    tagName: 'a'
    events:
      'click': 'openDialog'

    keybindings: [
      {
        key: 'ALT+F10 (Windows, Linux)',
        description: I18n.t('keybindings.open_toolbar', 'Open the editor\'s toolbar')
      },
      {
        key: 'ALT+FN+F10 (Mac)',
        description: I18n.t('keybindings.open_toolbar', 'Open the editor\'s toolbar')
      },
      {
        key: 'ALT+0',
        description: I18n.t('keybindings.open_dialog', 'Open this help dialog')
      }
    ]

    template: Template

    initialize: ->
      this.el.href = '#' # for keyboard accessibility

      $('<i class="icon-info" />').appendTo(this.el)
      $('<span class="screenreader-only" />')
        .text(I18n.t('dialog_title', 'Keyboard Shortcuts'))
        .appendTo(this.el)

    render: () ->
      templateData = {
        keybindings: this.keybindings
      }

      this.$dialog = $(this.template(templateData)).dialog({
        title: I18n.t('dialog_title', 'Keyboard Shortcuts'),
        width: 600,
        resizable: true
        autoOpen: false
      })

      $(document).on('keyup.tinymce_keyboard_shortcuts', @openDialogByKeybinding.bind(this))

      return this

    remove: () ->
      $(document).off('keyup.tinymce_keyboard_shortcuts')
      this.$dialog.dialog('destroy')

    openDialog: ->
      unless this.$dialog.dialog('isOpen')
        this.$dialog.dialog('open')

    openDialogByKeybinding: (e) ->
      if ZERO_KEYCODES.indexOf(e.keyCode) > -1 && e.altKey
        this.openDialog()

  KeyboardShortcuts
