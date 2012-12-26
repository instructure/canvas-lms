define [
  'i18n!editor'
  'jquery'
  'underscore'
  'Backbone'
  'jst/tinymce/EquationEditorView'

  'jqueryui/dialog'
  'mathquill'
], (I18n, $, _, Backbone, template) ->

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

    initialize: (@editor) ->
      # calling this just makes sure to get the css loaded
      @template()

      @$editor = $("##{@editor.id}")
      @prevSelection = @editor.selection.getBookmark()

      nodes = $('<span>').html @editor.selection.getContent()
      equation = getEquationText(nodes).replace(/^\s+|\s+$/g, '')

      @$el.dialog
        minWidth: 670
        minHeight: 290
        resizable: true
        title: I18n.t('equation_editor_title', 'Use the toolbars or type/paste in LaTeX format to add an equation')
        buttons: [
          class: 'btn-primary'
          text: I18n.t('button.insert_equation', 'Insert Equation')
          click: @onSubmit
        ]

      @$el
        .mathquill('revert')
        .addClass('mathquill-editor')
        .mathquill('editor')
        .mathquill('write', equation)
        .focus()

    restoreCaret: ->
      @editor.selection.moveToBookmark(@prevSelection)

    onSubmit: (event) =>
      event.preventDefault()
      text = @$el.mathquill('latex')
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
