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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import {reorderElements, renderTray} from '@canvas/move-item-tray'

const I18n = createI18nScope('course_navigation')
/*
xsslint jqueryObject.identifier dragObject current_item
*/

export default class NavigationView extends Backbone.View {
  static initClass() {
    this.prototype.events = {
      'click .disable_nav_item_link': 'disableNavLink',
      'click .move_nav_item_link': 'moveNavLink',
      'click .enable_nav_item_link': 'enableNavLink',
      'keydown .navitem.enabled': 'handleKeyboardNav',
      'focus .navitem.enabled': 'handleNavItemFocus',
      'blur .navitem.enabled': 'handleNavItemBlur',
    }

    this.prototype.els = {
      '#nav_enabled_list': '$enabled_list',
      '#nav_disabled_list': '$disabled_list',
      '.navitem': '$navitems',
    }
  }

  disableNavLink(e) {
    const $targetItem = $(e.currentTarget).closest('.navitem')
    this.$disabled_list.append($targetItem)
    $(e.currentTarget)
      .attr('class', '')
      .attr('class', 'icon-plus enable_nav_item_link')
      .text(I18n.t('Enable'))
    return $targetItem.find('a.al-trigger').focus()
  }

  enableNavLink(e) {
    const $targetItem = $(e.currentTarget).closest('.navitem')
    this.$enabled_list.append($targetItem)
    $(e.currentTarget)
      .attr('class', '')
      .attr('class', 'icon-x disable_nav_item_link')
      .text(I18n.t('Disable'))
    return $targetItem.find('a.al-trigger').focus()
  }

  moveNavLink(e) {
    const selectedItem = $(e.currentTarget).closest('.navitem')
    const navList = $(e.currentTarget).closest('.nav_list')
    const navOptions = navList
      .children('.navitem')
      .map((key, item) => ({
        id: item.getAttribute('id'),
        title: item.getAttribute('aria-label'),
      }))
      .toArray()

    this.moveTrayProps = {
      title: I18n.t('Move Navigation Item'),
      items: [
        {
          id: selectedItem.attr('id'),
          title: selectedItem.attr('aria-label'),
        },
      ],
      moveOptions: {
        siblings: navOptions,
      },
      onMoveSuccess: res => reorderElements(res.data, this.$enabled_list[0], id => `#${id}`),
      focusOnExit: item => document.querySelector(`#${item.id} a.al-trigger`),
    }

    return renderTray(this.moveTrayProps, document.getElementById('not_right_side'))
  }

  resetReadState(_e) {
    $('.drag_and_drop_warning').removeClass('read')
  }

  focusKeyboardHelp(_e) {
    if (!$('.drag_and_drop_warning').hasClass('read')) {
      $('.drag_and_drop_warning').removeClass('screenreader-only')
    }
  }

  hideKeyboardHelp(_e) {
    $('.drag_and_drop_warning').addClass('screenreader-only read')
  }

  handleNavItemFocus(e) {
    $(e.currentTarget).addClass('keyboard-focus')
  }

  handleNavItemBlur(e) {
    $(e.currentTarget).removeClass('keyboard-focus')
    if (this.isMovingItem) return

    const $target = $(e.relatedTarget)
    if (this.draggedItem && this.draggedItem[0] === e.currentTarget) {
      if (!$target.hasClass('navitem') && !$target.closest('.nav_list').length) {
        this.cancelDrag()
      }
    }
  }

  handleKeyboardNav(e) {
    const $currentItem = $(e.currentTarget)

    if ($(e.target).closest('.admin-links, .al-options').length) {
      return
    }

    if (e.key === 'ArrowUp') {
      e.preventDefault()
      if (this.draggedItem && this.draggedItem[0] === e.currentTarget) {
        const $prev = $currentItem.prev('.navitem.enabled')
        if ($prev.length) {
          this.isMovingItem = true
          $currentItem.insertBefore($prev)
          $currentItem.focus()
          this.isMovingItem = false
        }
      } else {
        const $prev = $currentItem.prev('.navitem.enabled')
        if ($prev.length) {
          $prev.focus()
        }
      }
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      if (this.draggedItem && this.draggedItem[0] === e.currentTarget) {
        const $next = $currentItem.next('.navitem.enabled')
        if ($next.length) {
          this.isMovingItem = true
          $currentItem.insertAfter($next)
          $currentItem.focus()
          this.isMovingItem = false
        }
      } else {
        const $next = $currentItem.next('.navitem.enabled')
        if ($next.length) {
          $next.focus()
        }
      }
    } else if (e.key === ' ') {
      e.preventDefault()
      if (this.draggedItem && this.draggedItem[0] === e.currentTarget) {
        this.dropItem($currentItem)
      } else {
        this.startDrag($currentItem)
      }
    } else if (e.key === 'Escape') {
      if (this.draggedItem) {
        e.preventDefault()
        this.cancelDrag()
      }
    }
  }

  startDrag($item) {
    this.draggedItem = $item
    const $prevSibling = $item.prev('.navitem.enabled')
    const $nextSibling = $item.next('.navitem.enabled')
    this.originalPrevSibling = $prevSibling.length ? $prevSibling : null
    this.originalNextSibling = $nextSibling.length ? $nextSibling : null
    $item.addClass('dragging')
    $item.attr('aria-grabbed', 'true')
    const label = $item.attr('aria-label')
    $.screenReaderFlashMessage(
      I18n.t('Grabbed %{item}. Use arrow keys to move, Space to drop, Escape to cancel.', {
        item: label,
      }),
    )
  }

  dropItem($item) {
    const label = $item.attr('aria-label')
    $item.removeClass('dragging')
    $item.attr('aria-grabbed', 'false')
    this.draggedItem = null
    this.originalPrevSibling = null
    this.originalNextSibling = null
    $.screenReaderFlashMessage(I18n.t('Dropped %{item}', {item: label}))
  }

  cancelDrag() {
    if (!this.draggedItem) return
    const $item = this.draggedItem
    const label = $item.attr('aria-label')
    $item.removeClass('dragging')
    $item.attr('aria-grabbed', 'false')

    if (this.originalPrevSibling) {
      $item.insertAfter(this.originalPrevSibling)
    } else if (this.originalNextSibling) {
      $item.insertBefore(this.originalNextSibling)
    }

    this.draggedItem = null
    this.originalPrevSibling = null
    this.originalNextSibling = null
    $.screenReaderFlashMessage(I18n.t('Cancelled move of %{item}', {item: label}))
  }

  afterRender() {
    $('#navigation_tab').on('blur', this.resetReadState)
    $('#tab-navigation').on('keyup', this.focusKeyboardHelp)
    $('.drag_and_drop_warning').on('blur', this.hideKeyboardHelp)

    this.$enabled_list.children('.navitem.enabled').attr('tabindex', '0')
  }
}
NavigationView.initClass()
