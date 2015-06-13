define [
  'i18n!editor'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/tinymce/EquationToolbarView'
  'jst/tinymce/EquationEditorView'
  'str/htmlEscape'

  'jqueryui/dialog'
  'mathquill'
], (I18n, $, _, Backbone, EquationToolbarView, template, htmlEscape) ->

  class EquationEditorView extends Backbone.View

    ##
    # class method
    #
    # like $.text() / Sizzle.getText(elems), except it also gets alt 
    #   attributes from images
    #
    # @param {jquery object} elems The collection of elements (or the
    # singular jquery element) that represents the currently selected
    #   thing in the editor to turn into an equation
    @getEquationText: (elems)->
      self = this
      _.map elems, (elem) ->
        # Get the text from text nodes and CDATA nodes
        if elem.nodeType in [3,4]
          if elem.nodeValue.match(/^<img/)
            #if the "text" is really just an unparsed "img" node
            # then we really want the alt element
            self.getEquationText($(elem.nodeValue))
          else
            elem.nodeValue

        # Get alt attributes from IMG nodes
        else if elem.nodeName is 'IMG' && elem.className is 'equation_image'
          elem.alt

        # Traverse everything else, except comment nodes
        else if elem.nodeType isnt 8
          self.getEquationText( elem.childNodes )
      .join('')

    getEquationText: (elems)->
      @constructor.getEquationText(elems)

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
        nodes = $('<span>').text @editor.selection.getNode()
        equation = @getEquationText(nodes).replace(/^\s+|\s+$/g, '')
        @addToolbar(equation)

      @cacheEls()

      @$el.dialog
        minWidth: 670
        minHeight: 290
        resizable: false
        title: I18n.t('equation_editor_title', 'Use the toolbars here, or Switch View to Advanced to type/paste in LaTeX')
        dialogClass: 'math-dialog'
        open: @initialRender
        close: @onClose
        buttons: [
          {
            class: 'btn-primary'
            text: I18n.t('button.insert_equation', 'Insert Equation')
            click: @onSubmit
          }
        ]


    onClose: (e, ui) =>
      @restoreCaret()

    initialRender: =>
      nodes = $('<span>').text @editor.selection.getContent()
      equation = @getEquationText(nodes).replace(/^\s+|\s+$/g, '')

      @$mathjaxMessage.empty()
      @setView(@$el.data('view'), equation)
      @renderEquation(@opposite(@$el.data('view')), '')

    addToolbar: (equation) ->
      @$el.append(@template)

      $('#mathjax-preview').html("<script type='math/tex; mode=display'>#{htmlEscape equation}</script>")
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

    toggleView: (e) =>
      e.preventDefault()
      view = @$el.data('view')
      equation = @getEquation()
      @$mathjaxMessage.empty()
      @setView(@opposite(view), equation)

    setView: (view, equation) =>
      if view == 'mathquill'
        @$mathjaxView.hide()
        @$mathquillView.show()
        setTimeout( =>
          @$mathquillView.find('.mathquill-tab-bar li.mathquill-tab-selected a').focus()
        , 200)
      else if view == 'mathjax'
        @$mathquillView.hide()
        @$mathjaxView.show()
        @$mathjaxView.find('.mathquill-tab-bar li.mathquill-tab-selected a').focus()

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
          @$mathjaxMessage.text(I18n.t('cannot_render_equation', "This equation cannot be rendered in Basic View."))
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
