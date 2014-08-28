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
      @_highlightSelectedColor()

    ### PRIVATE FUNCTIONS ###
    _highlightSelectedColor: ->
      $("body").on 'click', '.mceColorSplitMenu td', ->
        $(this).parentsUntil(".mceColorSplitMenu").find(".selectedColor").removeClass("selectedColor")
        $(this).addClass("selectedColor")

    _cacheElements: ->
      @$iframe = @$el.find(".mceIframeContainer iframe")

    _addLabels: ->
      @$el.find("##{@id_prepend}_fontsizeselect_voiceDesc").text(I18n.t('titles.font_size',"Font Size, press down to select"))
      @$el.find("##{@id_prepend}_formatselect_voiceDesc").text(I18n.t('titles.formatting',"Formatting, press down to select"))
      @$el.find("##{@id_prepend}_forecolor_voice").text(I18n.t('accessibles.forecolor',"Text Color, press down to select"))
      @$el.find("##{@id_prepend}_backcolor_voice").text(I18n.t('accessibles.background_color',"Background Color, press down to select"))

      @$el.find("##{@id_prepend}_instructure_record").attr('aria-disabled', 'true')
      @$el.find("##{@id_prepend}_instructure_record").removeAttr('role')
      @$el.find("##{@id_prepend}_instructure_record_voice").append('<br/>').append(I18n.t('accessibles.record', 'This feature is inaccessible for screen readers.'))
      @$el.find("##{@id_prepend}_instructure_record img").attr('alt',
        @$el.find("##{@id_prepend}_instructure_record img").attr('alt') + ", " + I18n.t('accessibles.record', 'This feature is inaccessible for screen readers.'));

    _addTitles: ->
      @$iframe.attr 'title', I18n.t('titles.rte_help', 'Rich Text Area. Press ALT F10 for toolbar. Press ALT F8 for help.')
