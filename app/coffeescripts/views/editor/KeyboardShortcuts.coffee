define [
  'underscore'
  'i18n!editor.keyboard_shortcuts'
  'jquery'
  'Backbone'
  'jst/editor/KeyboardShortcuts'
], (_, I18n, $, Backbone, Template) ->
  HELP_KEYCODES = [
    48 # regular 0 (not numpad 0)
    119 # F8
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
        key: 'ALT+F9',
        description: I18n.t('keybindings.open_menubar', 'Open the editor\'s menubar')
      },
      {
        key: 'ALT+F10',
        description: I18n.t('keybindings.open_toolbar', 'Open the editor\'s toolbar')
      },
      {
        key: 'ESC',
        description: I18n.t('keybindings.close_submenu', 'Close menu or dialog, also gets you back to editor area')
      },
      {
        key: 'TAB/Arrows',
        description: I18n.t('keybindings.navigate_toolbar', 'Navigate left/right through menu/toolbar')
      },
      {
        key: 'ALT+F8',
        description: I18n.t('keybindings.open_dialog', 'Open this help dialog')
      }
    ]

    template: Template

    initialize: ->
      this.el.href = '#' # for keyboard accessibility
      $(this.el).attr("title", I18n.t("editor_help_link", "Open Help Menu"))

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

      @bindEvents()

      return this

    bindEvents: ()->
      $(document).on('keyup.tinymce_keyboard_shortcuts', @openDialogByKeybinding.bind(this))

      #special event for keyups in the editor iframe, fired from "tinymce.editor_box.js"
      $(document).on('editorKeyUp', ((e, originalEvent)->
        @openDialogByKeybinding(originalEvent)
      ).bind(this))


    remove: () ->
      $(document).off('keyup.tinymce_keyboard_shortcuts')
      $(document).off('editorKeyUp')
      this.$dialog.dialog('destroy')

    openDialog: ->
      unless this.$dialog.dialog('isOpen')
        this.$dialog.dialog('open')

    openDialogByKeybinding: (e) ->
      if HELP_KEYCODES.indexOf(e.keyCode) > -1 && e.altKey
        this.openDialog()

  KeyboardShortcuts
