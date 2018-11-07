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

import _ from 'underscore'
import I18n from 'i18n!editor'
import $ from 'jquery'
import Backbone from 'Backbone'
import preventDefault from '../fn/preventDefault'
import KeyboardShortcuts from '../views/editor/KeyboardShortcuts'
import React from 'react'
import ReactDOM from 'react-dom'
import SwitchEditorControl from 'jsx/editor/SwitchEditorControl'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'

RichContentEditor.preloadRemoteModule()

/*
xsslint safeString.property content
xsslint safeString.property textArea
*/

// Simply returns a unique number with each call
let _nextID = 0
const nextID = () => `editor-toggle-${(_nextID += 1)}`

// #
// Toggles an element between a rich text editor and itself
class EditorToggle {
  options = {
    // text to display in the "done" button
    doneText: I18n.t('done_as_in_finished', 'Done'),
    // whether or not a "Switch Views" link should be provided to edit the
    // raw html
    switchViews: true
  }

  // #
  // @param {jQueryEl} @el - the element containing html to edit
  // @param {Object} options
  constructor(elem, options) {
    this.editingElement(elem)
    this.options = $.extend({}, this.options, options)
    this.textArea = this.createTextArea()
    this.textAreaContainer = $('<div/>').append(this.textArea)

    if (this.options.switchViews) {
      this.switchViews = this.createSwitchViews()
    }
    this.done = this.createDone()
    this.content = this.getContent()
    this.editing = false
  }

  // #
  // Toggles between editing the content and displaying it
  // @api public
  toggle() {
    if (!this.editing) {
      return this.edit()
    } else {
      return this.display()
    }
  }

  // #
  // Compiles the options for the RichContentEditor
  // @api private
  getRceOptions() {
    const opts = $.extend(
      {
        focus: true,
        tinyOptions: this.options.tinyOptions || {}
      },
      this.options.rceOptions
    )
    if (this.options.editorBoxLabel) {
      opts.tinyOptions.aria_label = this.options.editorBoxLabel
    }
    return opts
  }

  // #
  // Converts the element to an editor
  // @api public
  edit() {
    this.textArea.val(this.getContent())
    this.textAreaContainer.insertBefore(this.el)
    this.el.detach()
    if (this.options.switchViews) {
      this.switchViews = this.createSwitchViews()
      this.switchViews.insertBefore(this.textAreaContainer)
    }
    if (!this.infoIcon) {
      this.infoIcon = new KeyboardShortcuts().render().$el
    }
    this.infoIcon.insertBefore($('.switch-views__link'))
    $('<div/>', {style: 'clear: both'}).insertBefore(this.textAreaContainer)
    this.done.insertAfter(this.textAreaContainer)
    RichContentEditor.initSidebar()
    RichContentEditor.loadNewEditor(this.textArea, this.getRceOptions())
    this.textArea = RichContentEditor.freshNode(this.textArea)
    this.editing = true
    return this.trigger('edit')
  }

  replaceTextArea() {
    this.el.insertBefore(this.textAreaContainer)
    RichContentEditor.destroyRCE(this.textArea)
    if (this.textArea) {
      this.textArea.remove()
    }
    this.textArea = this.createTextArea()
    this.textAreaContainer.append(this.textArea)
    return this.textAreaContainer.detach()
  }

  // #
  // Converts the editor to an element
  // @api public
  display(opts) {
    if (!(opts != null ? opts.cancel : undefined)) {
      this.content = RichContentEditor.callOnRCE(this.textArea, 'get_code')
      this.textArea.val(this.content)
      this.el.html(this.content)
    }
    this.replaceTextArea()
    if (this.options.switchViews) {
      this.switchViews.detach()
    }
    this.infoIcon.detach()
    this.done.detach()
    this.editing = false
    return this.trigger('display')
  }

  // #
  // Assign/re-assign the jQuery element to to edit.
  //
  // @param {jQueryEl} @el - the element containing html to edit
  // @api public
  editingElement(elem) {
    return (this.el = elem)
  }

  // #
  // method to get the content for the editor
  // @api private
  getContent() {
    // remove MathML additions
    const content = $('<div></div>').append($(this.el.html()))
    content.find('.hidden-readable').remove()
    return $.trim(content.html())
  }

  // #
  // creates the textarea tinymce uses for the editor
  // @api private
  createTextArea() {
    return (
      $('<textarea/>')
        // tiny mimics the width of the textarea. its min height is 110px, so
        // we want the textarea at least that big as well
        .css({
          width: '100%',
          minHeight: '110px'
        })
        .addClass('editor-toggle')
        .attr('id', nextID())
    )
  }

  // #
  // creates the "done" button used to exit the editor
  // @api private
  createDone() {
    return $('<div/>')
      .addClass('edit_html_done_wrapper')
      .append(
        $('<a/>')
          .text(this.options.doneText)
          .attr('href', '#')
          .addClass('btn edit_html_done')
          .attr('title', I18n.t('done.title', 'Click to finish editing the rich text area'))
          .click(
            preventDefault(() => {
              this.display()
              this.editButton && this.editButton.focus()
            })
          )
      )
  }

  // #
  // create the switch views links to go between rich text and a textarea
  // @api private
  createSwitchViews() {
    const component = <SwitchEditorControl textarea={this.textArea} />
    const $container = $("<div class='switch-views'></div>")
    ReactDOM.render(component, $container[0])
    return $container
  }
}

_.extend(EditorToggle.prototype, Backbone.Events)

export default EditorToggle
