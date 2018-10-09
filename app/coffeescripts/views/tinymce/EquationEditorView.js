//
// Copyright (C) 2012 - present Instructure, Inc.
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

import I18n from 'i18n!editor'
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import EquationToolbarView from './EquationToolbarView'
import template from 'jst/tinymce/EquationEditorView'
import htmlEscape from 'str/htmlEscape'
import preventDefault from '../../fn/preventDefault'
import * as RceCommandShim from 'jsx/shared/rce/RceCommandShim'
import 'jqueryui/dialog'
import 'mathquill'

export default class EquationEditorView extends Backbone.View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.onClose = this.onClose.bind(this)
    this.initialRender = this.initialRender.bind(this)
    this.toggleView = this.toggleView.bind(this)
    this.setView = this.setView.bind(this)
    this.onSubmit = this.onSubmit.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.template = template

    // all instances share same element
    this.prototype.el = $(document.createElement('div')).appendTo('body')[0]

    this.prototype.els = {
      '#mathquill-view': '$mathquillView',
      '#mathquill-container': '$mathquillContainer',
      '#mathjax-view': '$mathjaxView',
      '#mathjax-editor': '$mathjaxEditor',
      '#mathjax-message': '$mathjaxMessage'
    }
  }

  //#
  // class method
  //
  // like $.text() / Sizzle.getText(elems), except it also gets alt
  //   attributes from images
  //
  // @param {jquery object} elems The collection of elements (or the
  // singular jquery element) that represents the currently selected
  //   thing in the editor to turn into an equation
  static getEquationText(elems) {
    const self = this
    return _.map(elems, function(elem) {
      // Get the text from text nodes and CDATA nodes
      if ([3, 4].includes(elem.nodeType)) {
        if (elem.nodeValue.match(/^<img/)) {
          //if the "text" is really just an unparsed "img" node
          // then we really want the alt element
          return self.getEquationText($(elem.nodeValue))
        } else {
          return elem.nodeValue
        }

        // Get alt attributes from IMG nodes
      } else if (elem.nodeName === 'IMG' && elem.className === 'equation_image') {
        if (elem.dataset.equationContent) {
          return elem.dataset.equationContent
        } else {
          return elem.alt
        }

        // Traverse everything else, except comment nodes
      } else if (elem.nodeType !== 8) {
        return self.getEquationText(elem.childNodes)
      }
    }).join('')
  }

  getEquationText(elems) {
    return this.constructor.getEquationText(elems)
  }

  initialize(editor) {
    this.editor = editor
    this.$editor = $(`#${this.editor.id}`)
    this.prevSelection = this.editor.selection.getBookmark()

    if (!(this.toolbar = this.$el.data('toolbar'))) {
      const nodes = $('<span>').text(this.editor.selection.getNode())
      const equation = this.getEquationText(nodes).replace(/^\s+|\s+$/g, '')
      this.addToolbar(equation)
    }

    this.cacheEls()
    this.$el.click(preventDefault(function() {}))
    return this.$el.dialog({
      minWidth: 670,
      minHeight: 290,
      resizable: false,
      title: I18n.t(
        'equation_editor_title',
        'Use the toolbars here, or Switch View to Advanced to type/paste in LaTeX'
      ),
      dialogClass: 'math-dialog',
      open: this.initialRender,
      close: this.onClose,
      buttons: [
        {
          class: 'btn-primary',
          text: I18n.t('button.insert_equation', 'Insert Equation'),
          click: this.onSubmit
        }
      ]
    })
  }

  onClose(e, ui) {
    return this.restoreCaret()
  }

  initialRender() {
    const nodes = $('<span>').text(this.editor.selection.getContent())
    const equation = this.getEquationText(nodes).replace(/^\s+|\s+$/g, '')

    this.$mathjaxMessage.empty()
    this.setView(this.$el.data('view'), equation)
    return this.renderEquation(this.opposite(this.$el.data('view')), '')
  }

  addToolbar(equation) {
    this.$el.append(this.template)

    $('#mathjax-preview').html(
      `<script type='math/tex; mode=display'>${htmlEscape(equation)}</script>`
    )
    this.toolbar = new EquationToolbarView({
      el: this.$el
    })
    this.toolbar.render()

    $('a.math-toggle-link').bind('click', this.toggleView)

    this.$el.data('toolbar', this.toolbar)
    return this.$el.data('view', 'mathquill')
  }

  opposite(view) {
    if (view === 'mathquill') {
      return 'mathjax'
    } else if (view === 'mathjax') {
      return 'mathquill'
    }
  }

  getEquation() {
    const view = this.$el.data('view')
    if (view === 'mathquill') {
      return this.$mathquillContainer.mathquill('latex')
    } else if (view === 'mathjax') {
      return this.$mathjaxEditor.val()
    }
  }

  toggleView(e) {
    e.preventDefault()
    const view = this.$el.data('view')
    const equation = this.getEquation()
    this.$mathjaxMessage.empty()
    return this.setView(this.opposite(view), equation)
  }

  setView(view, equation) {
    if (view === 'mathquill') {
      this.$mathjaxView.hide()
      this.$mathquillView.show()
      setTimeout(() => {
        return this.$mathquillView.find('.mathquill-tab-bar li.mathquill-tab-selected a').focus()
      }, 200)
    } else if (view === 'mathjax') {
      this.$mathquillView.hide()
      this.$mathjaxView.show()
      this.$mathjaxView.find('.mathquill-tab-bar li.mathquill-tab-selected a').focus()
    }

    if (!this.renderEquation(view, equation)) {
      return this.setView('mathjax', equation)
    } else {
      return this.$el.data('view', view)
    }
  }

  renderEquation(view, equation) {
    if (view === 'mathquill') {
      this.$mathquillContainer
        .mathquill('revert')
        .addClass('mathquill-editor')
        .mathquill('editor')
        .mathquill('write', equation)
      if (
        this.$mathquillContainer.mathquill('latex').replace(/\s+/, '') !==
        equation.replace(/\s+/, '')
      ) {
        this.$mathjaxMessage.text(
          I18n.t('cannot_render_equation', 'This equation cannot be rendered in Basic View.')
        )
        return false
      }
    } else if (view === 'mathjax') {
      this.$mathjaxEditor.val(equation)
      if (this.toolbar.renderPreview) {
        this.toolbar.renderPreview()
      }
    }

    return true
  }

  restoreCaret() {
    return this.editor.selection.moveToBookmark(this.prevSelection)
  }

  // the following is here to make it easier to unit test
  static doubleEncodeEquationForUrl(text) {
    return encodeURIComponent(encodeURIComponent(text))
  }

  // the following will be called by onSubmit below
  doubleEncodeEquationForUrl(text) {
    return this.constructor.doubleEncodeEquationForUrl(text)
  }

  onSubmit(event) {
    event.preventDefault()

    const text = this.getEquation()
    const altText = `LaTeX: ${text}`
    const url = `/equation_images/${this.doubleEncodeEquationForUrl(text)}`
    const $img = $(document.createElement('img')).attr({
      src: url,
      alt: altText,
      title: text,
      class: 'equation_image',
      'data-equation-content': text
    })
    const $div = $(document.createElement('div')).append($img)

    this.restoreCaret()
    RceCommandShim.send(this.$editor, 'insert_code', $div.html())
    return this.$el.dialog('close')
  }
}
EquationEditorView.initClass()
