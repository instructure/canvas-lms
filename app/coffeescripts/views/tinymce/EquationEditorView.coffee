define [
  'i18n!editor'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/tinymce/EquationToolbarView'
  'jst/tinymce/EquationEditorView'

  'jqueryui/dialog'
  'mathquill'
], (I18n, $, _, Backbone, EquationToolbarView, template) ->

  # like $.text() / Sizzle.getText(elems), except it also gets alt attributes from images
  getEquationText = (elems) ->
    _.map elems, (elem) ->
      # Get the text from text nodes and CDATA nodes
      if elem.nodeType in [3,4]
        elem.nodeValue

      # Get alt attributes from IMG nodes
      else if elem.nodeName is 'IMG' && elem.className is 'equation_image'
        elem.alt

      # Traverse everything else, except comment nodes
      else if elem.nodeType isnt 8
        getEquationText( elem.childNodes )
    .join('')


  class EquationEditorView extends Backbone.View

    template: template

    # all instances share same element
    el: $(document.createElement('span')).appendTo('body')[0]

    els:
      '#mathquill-view': '$mathquillView'
      '#mathquill-container': '$mathquillContainer'
      '#mathjax-view': '$mathjaxView'
      '#mathjax-editor': '$mathjaxEditor'
      '#mathjax-message': '$mathjaxMessage'

    initialize: (@editor) ->
      @$editor = $("##{@editor.id}")
      @prevSelection = @editor.selection.getBookmark()

      unless @toolbar = @$el.data('toolbar')
        nodes = $('<span>').html @editor.selection.getContent()
        equation = getEquationText(nodes).replace(/^\s+|\s+$/g, '')
        @addToolbar(equation)

      @cacheEls()

      @$el.dialog
        minWidth: 670
        minHeight: 290
        resizable: false
        title: I18n.t('equation_editor_title', 'Use the toolbars here, or Switch View to Advanced to type/paste in LaTeX')
        dialogClass: 'math-dialog'
        open: @initialRender
        buttons: [
          {
            class: 'btn-primary'
            text: I18n.t('button.insert_equation', 'Insert Equation')
            click: @onSubmit
          }
        ]

    initialRender: =>
      nodes = $('<span>').html @editor.selection.getContent()
      equation = getEquationText(nodes).replace(/^\s+|\s+$/g, '')

      @$mathjaxMessage.empty()
      @setView(@$el.data('view'), equation)
      @renderEquation(@opposite(@$el.data('view')), '')

    addToolbar: (equation) ->
      @$el.append(@template)

      $('#mathjax-preview').html("<script type='math/tex; mode=display'>#{equation}</script>")
      @toolbar = new EquationToolbarView
        el: @$el
      @toolbar.render()

      $('a.math-toggle-link').bind('click', @toggleView)

      @$el.data('toolbar', @toolbar)
      @$el.data('view', 'mathquill')

    opposite: (view) ->
      if view == 'mathquill'
        return 'mathjax'
      else if view == 'mathjax'
        return 'mathquill'

    getEquation: ->
      view = @$el.data('view')
      if view == 'mathquill'
        return @$mathquillContainer.mathquill('latex')
      else if view == 'mathjax'
        return @$mathjaxEditor.val()

    toggleView: =>
      view = @$el.data('view')
      equation = @getEquation()
      @$mathjaxMessage.empty()
      @setView(@opposite(view), equation)

    setView: (view, equation) =>
      if view == 'mathquill'
        @$mathjaxView.hide()
        @$mathquillView.show()
      else if view == 'mathjax'
        @$mathquillView.hide()
        @$mathjaxView.show()

      if !@renderEquation(view, equation)
        @setView('mathjax', equation)
      else
        @$el.data('view', view)

    renderEquation: (view, equation) ->
      if view == 'mathquill'
        @$mathquillContainer
          .mathquill('revert')
          .addClass('mathquill-editor')
          .mathquill('editor')
          .mathquill('write', equation)
        if @$mathquillContainer.mathquill('latex').replace(/\s+/, '') != equation.replace(/\s+/, '')
          @$mathjaxMessage.html(I18n.t('cannot_render_equation', "This equation cannot be rendered in Basic View."))
          return false
      else if view == 'mathjax'
        @$mathjaxEditor.val(equation)
        if @toolbar.renderPreview
          @toolbar.renderPreview()

      return true

    restoreCaret: ->
      @editor.selection.moveToBookmark(@prevSelection)

    onSubmit: (event) =>
      event.preventDefault()

      text = @getEquation()
      url = "/equation_images/#{ encodeURIComponent escape text }"
      $img = $(document.createElement('img')).attr
        src: url
        alt: text
        title: text
        class: 'equation_image'
      $div = $(document.createElement('div')).append($img)

      @restoreCaret()
      @$editor.editorBox 'insert_code', $div.html()
      @$el.dialog('close')