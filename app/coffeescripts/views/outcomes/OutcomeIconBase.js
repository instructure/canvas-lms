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
//

import $ from 'jquery'

import Backbone from 'Backbone'
import h from 'str/htmlEscape'
import 'jqueryui/draggable'

// This is the parent view for <li /> tags inside of an
// OutcomesDirectoryView. It handles dragging functionality
// and provides an API for keydown events and for selecting
// elements.
export default class OutcomeIconBase extends Backbone.View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.triggerSelect = this.triggerSelect.bind(this)
    this.select = this.select.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.tagName = 'li'

    this.prototype.attributes = {tabindex: -1}

    this.prototype.events = {
      click: 'triggerSelect',
      keydown: 'onKeydown',
      focus: 'onFocus'
    }

    this.prototype.keyCodes = {
      13: 'Action',
      32: 'Action',
      37: 'LeftArrow',
      38: 'UpArrow',
      39: 'RightArrow',
      40: 'DownArrow'
    }
  }

  initialize(opts) {
    super.initialize(...arguments)
    this.readOnly = opts.readOnly
    this.dir = opts.dir
    return this.attachEvents()
  }

  // Internal: Attach events to the associated model.
  //
  // Returns nothing.
  attachEvents() {
    this.model.on('change:title', this.updateTitle, this)
    this.model.on('remove', this.remove, this)
    return this.model.on('select', this.triggerSelect, this)
  }

  // Public: Fire a 'select' event for listeners and then select self.
  //
  // "Selecting" an OutcomeIcon involves updating the styles and other display
  // properties, but doesn't impact state at all.
  //
  // e - Event object. (optional)
  //
  // Returns nothing.
  triggerSelect(e) {
    if (e) {
      e.preventDefault()
    }
    this.trigger('select', this)
    return this.select()
  }

  // Internal: Route keydown events to their proper handlers.
  //
  // A handler follows the format "onEnterKey", where "Enter" is the key name.
  //
  // e - Event object.
  //
  // Returns nothing.
  onKeydown(e) {
    const $target = $(e.target)
    const fn = `on${this.keyCodes[e.keyCode]}Key`
    if (this[fn]) {
      return this[fn].call(this, e, $target) && e.preventDefault()
    }
  }

  // Internal: Navigate to the IconView above this one.
  //
  // Returns nothing.
  onUpArrowKey(e, $target) {
    return $target.prev().focus()
  }

  // Internal: Navigate to the IconView below this one.
  //
  // Returns nothing.
  onDownArrowKey(e, $target) {
    return $target.next().focus()
  }

  // Internal: Navigate to the previous level.
  //
  // Returns nothing.
  onLeftArrowKey(e, $target) {
    if (!($target.parent().prev().length > 0)) return
    return this.$el
      .parent()
      .prev()
      .find('[aria-expanded=true]')
      .click()
      .attr('aria-expanded', false)
      .attr('tabindex', 0)
      .focus()
  }

  // Internal: Trigger a select when enter key is pressed.
  //
  // Returns nothing.
  onActionKey(e, $target) {
    if ($target.hasClass('outcome-group')) {
      return this.onRightArrowKey(e, $target)
    } else {
      return this.triggerSelect()
    }
  }

  // Internal: Update tabindex on $el and its siblings.
  //
  // Returns nothing.
  onFocus(e) {
    const $target = $(e.target)
    $target
      .parents('.wrapper:first')
      .find('[tabindex=0]')
      .attr('tabindex', -1)
    return $target.attr('tabindex', 0)
  }

  // Internal: Makes an element focusable
  //
  // Returns jQuery element
  makeFocusable() {
    this.$el
      .parent()
      .find('[tabindex=0]')
      .attr('tabindex', -1)
    return this.$el.attr('tabindex', 0)
  }

  // Internal: Add selected class to <li />.
  //
  // Returns jQuery element.
  select() {
    this.makeFocusable()
    return this.$el.addClass('selected')
  }

  // Internal: Remove selected class to <li />.
  //
  // Returns jQuery element.
  unSelect() {
    return this.$el.removeClass('selected')
  }

  // Internal: Clean up event handlers prior to destroying object.
  //
  // Returns nothing.
  remove() {
    this.model.off('change:title', this.updateTitle, this)
    this.model.off('remove', this.remove, this)
    this.model.off('select', this.triggerSelect, this)
    return super.remove(...arguments)
  }

  // Public: Update display title to match the model's title.
  //
  // Returns nothing.
  updateTitle() {
    this.$('span').text(this.model.get('title'))
    return this.$('a').attr('title', h(this.model.get('title')))
  }

  // Public: Init dragging and render view.
  //
  // Returns self.
  render() {
    if (!this.readOnly) this.initDraggable()
    this.$el.data('view', this)
    return this
  }

  // Internal: Set up jQuery dragging and store view ref. on the element.
  //
  // Returns nothing.
  initDraggable() {
    return this.$el.draggable({
      scope: 'outcomes',
      containment: '.outcomes-sidebar',
      opacity: 0.7,
      helper: 'clone',
      revert: 'invalid',
      scroll: false,
      drag(event, ui) {
        const i = $(this).data('draggable')
        const o = i.options
        let scrolled = false
        const sidebar = i.relative_container
        const sidebarOffsetLeft = sidebar.offset().left
        const sidebarWidth = sidebar.width()

        if (event.pageX - sidebarOffsetLeft < o.scrollSensitivity) {
          sidebar[0].scrollLeft = scrolled = sidebar[0].scrollLeft - o.scrollSpeed
        } else if (sidebarOffsetLeft + sidebarWidth - event.pageX < o.scrollSensitivity) {
          sidebar[0].scrollLeft = scrolled = sidebar[0].scrollLeft + o.scrollSpeed
        }

        if (scrolled !== false && $.ui.ddmanager && !o.dropBehaviour) {
          return $.ui.ddmanager.prepareOffsets(i, event)
        }
      }
    })
  }
}
OutcomeIconBase.initClass()
