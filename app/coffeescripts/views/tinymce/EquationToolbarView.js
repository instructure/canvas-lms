//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import Backbone from 'Backbone'
import template from 'jst/tinymce/EquationToolbarView'
import {loadMathJax} from 'mathml'
import 'mathquill'

export default class EquationToolbarView extends Backbone.View {
  static initClass() {
    this.prototype.template = template

    this.prototype.els = {
      '#mathjax-view .mathquill-toolbar': '$toolbar',
      '#mathjax-editor': '$matheditor'
    }
  }

  render() {
    this.cacheEls()
    this.$toolbar.append(this.template())

    const $tabLinks = $('#mathjax-view .mathquill-tab-bar li a')
    $tabLinks
      .click(function(e) {
        e.preventDefault()
        $('#mathjax-view .mathquill-tab-bar li').removeClass('mathquill-tab-selected')
        $tabLinks.attr('aria-selected', 'false').attr('tabindex', '-1')
        $('#mathjax-view .mathquill-tab-pane').removeClass('mathquill-tab-pane-selected')
        $(this)
          .parent()
          .addClass('mathquill-tab-selected')
        $(this)
          .attr('aria-selected', 'true')
          .attr('tabindex', 0)
          .focus()
        $(this.href.replace(/.*#/, '#')).addClass('mathquill-tab-pane-selected')
      })
      .keydown(function(e) {
        let direction
        switch (e.keyCode) {
          case 37:
            direction = 'l'
            break
          case 39:
            direction = 'r'
            break
          default:
            return true
        }
        e.preventDefault()
        let listIndex = $tabLinks.index(this)
        // Don't fall off the right end of the list.
        // No need to worry about falling off the left end, as .get accepts negative indexes.
        if (listIndex === $tabLinks.length - 1 && direction === 'r') listIndex = -1
        if (direction === 'r') {
          listIndex++
        } else {
          listIndex--
        }
        $($tabLinks.get(listIndex))
          .focus()
          .click()
      })

    $('#mathjax-view .mathquill-tab-bar li:first-child').addClass('mathquill-tab-selected')

    return loadMathJax('TeX-AMS_HTML.js', this.addMathJaxEvents.bind(this))
  }

  addMathJaxEvents() {
    function renderPreview() {
      const jax = MathJax.Hub.getAllJax('mathjax-preview')[0]
      if (jax) {
        const tex = $('#mathjax-editor').val()
        return MathJax.Hub.Queue(['Text', jax, tex])
      }
    }

    $('#mathjax-view a.mathquill-rendered-math')
      .mousedown(e => e.stopPropagation())
      .click(function(e) {
        e.preventDefault()
        const text = this.title + ' '
        const field = document.getElementById('mathjax-editor')
        if (document.selection) {
          const sel = document.selection.createRange()
          sel.text = text
        } else if (field.selectionStart || field.selectionStart === '0') {
          const s = field.selectionStart
          e = field.selectionEnd
          const val = field.value
          field.value = val.substring(0, s) + text + val.substring(e, val.length)
        } else {
          field.value += text
        }
        $(field).focus()

        return renderPreview()
      })

    this.renderPreview = renderPreview
    this.$matheditor.keyup(renderPreview)
    return this.$matheditor.bind('paste', renderPreview)
  }
}
EquationToolbarView.initClass()
