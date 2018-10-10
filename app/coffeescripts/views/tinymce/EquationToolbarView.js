#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'jquery'
  'Backbone'
  'jst/tinymce/EquationToolbarView'
  'mathml'
  'mathquill'
], ($, Backbone, template, mathml) ->

  class EquationToolbarView extends Backbone.View

    template: template

    els:
      '#mathjax-view .mathquill-toolbar': '$toolbar'
      '#mathjax-editor': '$matheditor'

    render: ->
      @cacheEls()
      @$toolbar.append(@template())

      $tabLinks = $('#mathjax-view .mathquill-tab-bar li a')
      $tabLinks.click( (e) ->
        e.preventDefault()
        $('#mathjax-view .mathquill-tab-bar li').removeClass('mathquill-tab-selected')
        $tabLinks.attr('aria-selected', 'false').attr('tabindex', '-1')
        $('#mathjax-view .mathquill-tab-pane').removeClass('mathquill-tab-pane-selected')
        $(this).parent().addClass('mathquill-tab-selected')
        $(this).attr('aria-selected', 'true').attr('tabindex', 0).focus()
        $(this.href.replace(/.*#/, '#')).addClass('mathquill-tab-pane-selected')
      ).keydown((e) ->
        switch e.keyCode
          when 37 then direction = 'l'
          when 39 then direction = 'r'
          else return true
        e.preventDefault()
        listIndex = $tabLinks.index this
        # Don't fall off the right end of the list.
        # No need to worry about falling off the left end, as .get accepts negative indexes.
        if listIndex is ($tabLinks.length-1) and direction is 'r' then listIndex = -1
        if direction is 'r' then listIndex++ else listIndex--
        $($tabLinks.get(listIndex)).focus().click()
      )
        
      $('#mathjax-view .mathquill-tab-bar li:first-child').addClass('mathquill-tab-selected')

      mathml.loadMathJax('TeX-AMS_HTML.js', @addMathJaxEvents)

    addMathJaxEvents: =>
      renderPreview = ->
        jax = MathJax.Hub.getAllJax("mathjax-preview")[0];
        if jax
          tex = $('#mathjax-editor').val()
          MathJax.Hub.Queue(["Text", jax, tex])

      $('#mathjax-view a.mathquill-rendered-math').mousedown( (e) ->
        e.stopPropagation()
      ).click( (e) ->
        e.preventDefault()
        text = this.title + ' '
        field = document.getElementById('mathjax-editor')
        if document.selection
          sel = document.selection.createRange()
          sel.text = text
        else if field.selectionStart || field.selectionStart == '0'
          s = field.selectionStart
          e = field.selectionEnd
          val = field.value
          field.value = val.substring(0, s) + text + val.substring(e, val.length)
        else
          field.value += text
        $(field).focus()

        renderPreview()
      )

      @renderPreview = renderPreview
      @$matheditor.keyup(renderPreview)
      @$matheditor.bind('paste', renderPreview)

