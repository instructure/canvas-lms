define [
  'i18n!editor_accessibility'
  'jquery'
  'str/htmlEscape'
], (I18n, $, htmlEscape) ->
  ##
  # Used to insert accessibility titles into core TinyMCE components
  class EditorAccessiblity
    constructor: (editor) ->
      @editor = editor
      @id_prepend = editor.id
      @$el = $ "##{editor.editorContainer.id}"

    accessiblize: ->
      @_cacheElements()
      @_addTitles()
      @_addLabels()
      @_accessiblizeMenubar()
      @_removeStatusbarFromTabindex()

    ### PRIVATE FUNCTIONS ###
    _cacheElements: ->
      @$iframe = @$el.find(".mce-edit-area iframe")

    _addLabels: ->
      @$el.find("div[aria-label='Font Sizes']").attr('aria-label', I18n.t('titles.font_size',"Font Size, press down to select"))
      @$el.find("div.mce-listbox.mce-last:not([aria-label])").attr('aria-label', I18n.t('titles.formatting',"Formatting, press down to select"))
      @$el.find("div[aria-label='Text color']").attr('aria-label', I18n.t('accessibles.forecolor',"Text Color, press down to select"))
      @$el.find("div[aria-label='Background color'").attr('aria-label', I18n.t('accessibles.background_color',"Background Color, press down to select"))

    _addTitles: ->
      @$iframe.attr 'title', I18n.t('titles.rte_help', 'Rich Text Area. Press ALT+F8 for help')

    # Hide the menubar until ALT+F9 is pressed.
    _accessiblizeMenubar: ->
      $menubar = @$el.find '.mce-menubar'
      $firstMenu = $menubar.find('.mce-menubtn').first()
      $menubar.hide()
      @editor.addShortcut 'Alt+F9', '', =>
        $menubar.show()
        $firstMenu.focus()
        # Once it's shown, we don't need to show it again, so replace this handler with one that just focuses.
        @editor.addShortcut 'Alt+F9', '', -> $firstMenu.focus()

    # keyboard only nav gets permastuck in the statusbar in FF. If you can't
    # click with a mouse, the only way out is to refresh the page.
    _removeStatusbarFromTabindex: ->
      $statusbar = @$el.find '.mce-statusbar > .mce-container-body'
      $statusbar.attr 'tabindex', -1
