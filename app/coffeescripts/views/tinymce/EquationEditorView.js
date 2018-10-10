#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!editor'
  'jquery'
  'underscore'
  'Backbone'
  './EquationToolbarView'
  'jst/tinymce/EquationEditorView'
  'str/htmlEscape'
  '../../fn/preventDefault'
  'jsx/shared/rce/RceCommandShim'
  'jqueryui/dialog'
  'mathquill'
], (I18n, $, _, Backbone, EquationToolbarView, template, htmlEscape,
      preventDefault, RceCommandShim) ->

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
          if elem.dataset.equationContent
            elem.dataset.equationContent
          else
            elem.alt

        # Traverse everything else, except comment nodes
        else if elem.nodeType isnt 8
          self.getEquationText( elem.childNodes )
      .join('')

    getEquationText: (elems)->
      @constructor.getEquationText(elems)

    template: template

    # all instances share same element
    el: $(document.createElement('div')).appendTo('body')[0]

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
      @$el.click(preventDefault ->)
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

    # the following is here to make it easier to unit test
    @doubleEncodeEquationForUrl: (text) ->
      encodeURIComponent encodeURIComponent text

    # the following will be called by onSubmit below
    doubleEncodeEquationForUrl: (text) ->
      @constructor.doubleEncodeEquationForUrl text

    onSubmit: (event) =>
      event.preventDefault()

      text = @getEquation()
      altText = "LaTeX: #{ text }"
      url = "/equation_images/#{ @doubleEncodeEquationForUrl text }"
      $img = $(document.createElement('img')).attr
        src: url
        alt: altText
        title: text
        class: 'equation_image'
        'data-equation-content': text
      $div = $(document.createElement('div')).append($img)

      @restoreCaret()
      RceCommandShim.send(@$editor, 'insert_code', $div.html())
      @$el.dialog('close')
