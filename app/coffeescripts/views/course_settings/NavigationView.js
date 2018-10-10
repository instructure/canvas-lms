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

import I18n from 'i18n!course_navigation'
import $ from 'jquery'
import Backbone from 'Backbone'
import {reorderElements, renderTray} from 'jsx/move_item'
/*
xsslint jqueryObject.identifier dragObject current_item
*/

export default class NavigationView extends Backbone.View {
  static initClass() {
    this.prototype.keyCodes = {
      32: 'Space',
      38: 'UpArrow',
      40: 'DownArrow'
    }

    this.prototype.events = {
      'click .disable_nav_item_link': 'disableNavLink',
      'click .move_nav_item_link': 'moveNavLink',
      'click .enable_nav_item_link': 'enableNavLink'
    }

    this.prototype.els = {
      '#nav_enabled_list': '$enabled_list',
      '#nav_disabled_list': '$disabled_list',
      '.navitem': '$navitems'
    }
  }

  disableNavLink(e) {
    const $targetItem = $(e.currentTarget).closest('.navitem')
    this.$disabled_list.append($targetItem)
    $(e.currentTarget)
      .attr('class', '')
      .attr('class', 'icon-plus enable_nav_item_link')
      .text('Enable')
    return $targetItem.find('a.al-trigger').focus()
  }

  enableNavLink(e) {
    const $targetItem = $(e.currentTarget).closest('.navitem')
    this.$enabled_list.append($targetItem)
    $(e.currentTarget)
      .attr('class', '')
      .attr('class', 'icon-x disable_nav_item_link')
      .text('Disable')
    return $targetItem.find('a.al-trigger').focus()
  }

  moveNavLink(e) {
    const selectedItem = $(e.currentTarget).closest('.navitem')
    const navList = $(e.currentTarget).closest('.nav_list')
    const navOptions = navList
      .children('.navitem')
      .map((key, item) => ({
        id: item.getAttribute('id'),
        title: item.getAttribute('aria-label')
      }))
      .toArray()

    this.moveTrayProps = {
      title: I18n.t('Move Navigation Item'),
      items: [
        {
          id: selectedItem.attr('id'),
          title: selectedItem.attr('aria-label')
        }
      ],
      moveOptions: {
        siblings: navOptions
      },
      onMoveSuccess: res => reorderElements(res.data, this.$enabled_list[0], id => `#${id}`),
      focusOnExit: item => document.querySelector(`#${item.id} a.al-trigger`)
    }

    return renderTray(this.moveTrayProps, document.getElementById('not_right_side'))
  }

  focusKeyboardHelp(e) {
    $('.drag_and_drop_warning').removeClass('screenreader-only')
  }

  hideKeyboardHelp(e) {
    $('.drag_and_drop_warning').addClass('screenreader-only')
  }

  afterRender() {
    this.keyCodes = typeof Object.freeze === 'function' ? Object.freeze(this.keyCodes) : undefined
    $('li.navitem').on('keydown', this.onKeyDown)
    $('#navigation_tab').on('blur', this.focusKeyboardHelp)
    $('.drag_and_drop_warning').on('blur', this.hideKeyboardHelp)
  }

  onKeyDown = e => {
    const $target = $(e.target)
    const fn = `on${this.keyCodes[e.keyCode]}Key`
    if (this[fn]) {
      return this[fn].call(this, e, $target) && e.preventDefault()
    }
  }

  // Internal: move to the previous element
  // or up to the enabled list if at the top of the disabled list
  // returns nothing
  onUpArrowKey(e, $target) {
    let prev = $target.prev('li.navitem')

    if (this.empty(prev)) {
      prev = $target.children('li.navitem').first()
    }

    if (this.empty(prev) && this.disabled($target)) {
      prev = this.$enabled_list.children('li.navitem').last()

      if (this.empty(prev)) {
        prev = this.$enabled_list
        prev.attr('tabindex', 0)
        prev.bind('keydown', this.onKeyDown)
      }
    }

    return prev.focus()
  }

  // Internal: move to the next element
  // or down to the disabled list if at the bottom of the enabled list
  // returns nothing
  onDownArrowKey(e, $target) {
    let next = $target.next('li.navitem')

    if (this.empty(next)) {
      next = $target.children('li.navitem').first()
    }

    if (this.empty(next) && this.enabled($target)) {
      next = this.$disabled_list.children('li.navitem').first()

      if (this.empty(next)) {
        next = this.$disabled_list
        next.attr('tabindex', -1)
        next.bind('keydown', this.onKeyDown)
      }
    }

    return next.focus()
  }

  // Internal: mark the current element to begin dragging
  // or drop the current element
  // returns nothing
  onSpaceKey(e, $target) {
    let dragObject
    if ((dragObject = this.$el.data('drag'))) {
      if (!$target.is(dragObject)) {
        // drop
        if ($target.is('li.navitem')) {
          $target.after(dragObject)
        } else {
          $target.append(dragObject)
          $target.attr('tabindex', -1)
          $target.unbind('keydown')
        }
      }

      dragObject.attr('aria-grabbed', false)
      this.$el.data('drag', null)
      return dragObject.focus()
    } else if ($target.is('li.navitem')) {
      $target.attr('aria-grabbed', true)
      dragObject = $target
      this.$el.data('drag', dragObject)
      dragObject.blur()
      return dragObject.focus()
    }
  }

  // Internal: returns whether the selector is empty
  empty(selector) {
    return selector.length === 0
  }

  // Internal: returns whether the element is inside the enabled list
  enabled(el) {
    return el.parent().attr('id') === this.$enabled_list.attr('id')
  }

  // Internal: returns whether the element is inside the enabled list
  disabled(el) {
    return el.parent().attr('id') === this.$disabled_list.attr('id')
  }
}
NavigationView.initClass()
