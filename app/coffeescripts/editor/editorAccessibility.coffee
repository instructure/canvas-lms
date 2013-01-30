define [
  'i18n!editor_accessibility'
  'jquery'
], (I18n, $) ->
  ##
  # Used to insert accessibility titles into core TinyMCE components
  class EditorAccessiblity
    constructor: (editor) ->
      @id_prepend = editor.editorId
      @$el = $ "##{editor.editorContainer}"

    accessiblize: ->
      @_cacheElements()
      @_addTitles()
      @_addLabels()

    ### PRIVATE FUNCTIONS ###
    _cacheElements: ->
      @$iframe = @$el.find(".mceIframeContainer iframe")

    _addLabels: ->
      @$el.find("##{@id_prepend}_fontsizeselect_voiceDesc").text(I18n.t('titles.font_size',"Font Size, press down to select"))
      @$el.find("##{@id_prepend}_formatselect_voiceDesc").text(I18n.t('titles.formatting',"Formatting, press down to select"))
      @$el.find("##{@id_prepend}_forecolor_voice").text(I18n.t('accessibles.forecolor',"Text Color, press down to select"))
      @$el.find("##{@id_prepend}_backcolor_voice").text(I18n.t('accessibles.background_color',"Background Color, press down to select"))

    _addTitles: ->
      @$iframe.attr 'title', I18n.t('titles.rte_help', 'Rich Text Area. Press ALT F10 for toolbar. Press ALT 0 for help.')
