/*
 * Copyright (C) 2025 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import NavigationView from '../NavigationView'

describe('NavigationView', () => {
  let view
  let $container

  beforeEach(() => {
    $container = $('<div id="tab-navigation-mount"></div>')
    $('body').append($container)

    const html = `
      <ul id="nav_enabled_list" class="nav_list">
        <li class="navitem enabled" id="nav_edit_tab_id_0" aria-label="Home" tabindex="0">
          <div class="draggable_handle"><i class="icon-drag-handle"></i></div>
          <div class="navitem_content">Home</div>
          <div class="admin-links">
            <a class="al-trigger" href="#"></a>
            <ul class="al-options">
              <li><a href="#" class="move_nav_item_link">Move</a></li>
            </ul>
          </div>
        </li>
        <li class="navitem enabled" id="nav_edit_tab_id_1" aria-label="Modules" tabindex="0">
          <div class="draggable_handle"><i class="icon-drag-handle"></i></div>
          <div class="navitem_content">Modules</div>
          <div class="admin-links">
            <a class="al-trigger" href="#"></a>
            <ul class="al-options">
              <li><a href="#" class="move_nav_item_link">Move</a></li>
            </ul>
          </div>
        </li>
        <li class="navitem enabled" id="nav_edit_tab_id_2" aria-label="Assignments" tabindex="0">
          <div class="draggable_handle"><i class="icon-drag-handle"></i></div>
          <div class="navitem_content">Assignments</div>
          <div class="admin-links">
            <a class="al-trigger" href="#"></a>
            <ul class="al-options">
              <li><a href="#" class="move_nav_item_link">Move</a></li>
            </ul>
          </div>
        </li>
      </ul>
      <ul id="nav_disabled_list" class="nav_list"></ul>
    `
    $container.html(html)

    view = new NavigationView({el: $container})
    view.render()
    view.afterRender()

    $.screenReaderFlashMessage = vi.fn()
  })

  afterEach(() => {
    view.remove()
    $container.remove()
    vi.clearAllMocks()
  })

  describe('keyboard navigation without drag mode', () => {
    it.skip('moves focus to previous item with up arrow', () => {
      const $items = $('.navitem.enabled')
      const $secondItem = $items.eq(1)
      const $firstItem = $items.eq(0)

      $secondItem.focus()
      $secondItem.trigger($.Event('keydown', {key: 'ArrowUp'}))

      expect(document.activeElement).toBe($firstItem[0])
    })

    it.skip('moves focus to next item with down arrow', () => {
      const $items = $('.navitem.enabled')
      const $firstItem = $items.eq(0)
      const $secondItem = $items.eq(1)

      $firstItem.focus()
      $firstItem.trigger($.Event('keydown', {key: 'ArrowDown'}))

      expect(document.activeElement).toBe($secondItem[0])
    })

    it('does not move focus past the first item', () => {
      const $items = $('.navitem.enabled')
      const $firstItem = $items.eq(0)

      $firstItem.focus()
      $firstItem.trigger($.Event('keydown', {key: 'ArrowUp'}))

      expect(document.activeElement).toBe($firstItem[0])
    })

    it('does not move focus past the last item', () => {
      const $items = $('.navitem.enabled')
      const $lastItem = $items.eq(2)

      $lastItem.focus()
      $lastItem.trigger($.Event('keydown', {key: 'ArrowDown'}))

      expect(document.activeElement).toBe($lastItem[0])
    })
  })

  describe('starting drag mode', () => {
    it.skip('enters drag mode when space is pressed', () => {
      const $item = $('.navitem.enabled').first()

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))

      expect($item.hasClass('dragging')).toBe(true)
      expect($item.attr('aria-grabbed')).toBe('true')
      expect(view.draggedItem[0]).toBe($item[0])
    })

    it.skip('announces drag start to screen readers', () => {
      const $item = $('.navitem.enabled').first()

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))

      expect($.screenReaderFlashMessage).toHaveBeenCalledWith(
        expect.stringContaining('Grabbed Home'),
      )
      expect($.screenReaderFlashMessage).toHaveBeenCalledWith(
        expect.stringContaining('arrow keys to move'),
      )
    })

    it.skip('stores references to original siblings', () => {
      const $items = $('.navitem.enabled')
      const $item = $items.eq(1)
      const $prevItem = $items.eq(0)
      const $nextItem = $items.eq(2)

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))

      expect(view.originalPrevSibling[0]).toBe($prevItem[0])
      expect(view.originalNextSibling[0]).toBe($nextItem[0])
    })
  })

  describe('moving items in drag mode', () => {
    beforeEach(() => {
      const $item = $('.navitem.enabled').eq(1)
      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      vi.clearAllMocks()
    })

    it.skip('moves item up when up arrow is pressed', () => {
      const $items = $('.navitem.enabled')
      const $draggedItem = $items.eq(1)

      $draggedItem.trigger($.Event('keydown', {key: 'ArrowUp'}))

      const $newItems = $('.navitem.enabled')
      expect($newItems.eq(0).attr('id')).toBe('nav_edit_tab_id_1')
      expect($newItems.eq(1).attr('id')).toBe('nav_edit_tab_id_0')
    })

    it.skip('moves item down when down arrow is pressed', () => {
      const $items = $('.navitem.enabled')
      const $draggedItem = $items.eq(1)

      $draggedItem.trigger($.Event('keydown', {key: 'ArrowDown'}))

      const $newItems = $('.navitem.enabled')
      expect($newItems.eq(1).attr('id')).toBe('nav_edit_tab_id_2')
      expect($newItems.eq(2).attr('id')).toBe('nav_edit_tab_id_1')
    })

    it('maintains focus on the dragged item while moving', () => {
      const $draggedItem = $('.navitem.enabled').eq(1)

      $draggedItem.trigger($.Event('keydown', {key: 'ArrowUp'}))

      expect(document.activeElement.id).toBe('nav_edit_tab_id_1')
    })

    it.skip('keeps drag mode active through multiple moves', () => {
      const $draggedItem = $('.navitem.enabled').eq(1)

      $draggedItem.trigger($.Event('keydown', {key: 'ArrowUp'}))
      $draggedItem.trigger($.Event('keydown', {key: 'ArrowDown'}))
      $draggedItem.trigger($.Event('keydown', {key: 'ArrowDown'}))

      expect($draggedItem.hasClass('dragging')).toBe(true)
      expect(view.draggedItem).toBeTruthy()
    })

    it('does not move item past the top', () => {
      const $items = $('.navitem.enabled')
      const $firstItem = $items.eq(0)
      $firstItem.focus()
      $firstItem.trigger($.Event('keydown', {key: ' '}))

      const initialOrder = $('.navitem.enabled')
        .map((i, el) => el.id)
        .get()

      $firstItem.trigger($.Event('keydown', {key: 'ArrowUp'}))

      const finalOrder = $('.navitem.enabled')
        .map((i, el) => el.id)
        .get()

      expect(finalOrder).toEqual(initialOrder)
    })

    it('does not move item past the bottom', () => {
      const $items = $('.navitem.enabled')
      const $lastItem = $items.eq(2)
      $lastItem.focus()
      $lastItem.trigger($.Event('keydown', {key: ' '}))

      const initialOrder = $('.navitem.enabled')
        .map((i, el) => el.id)
        .get()

      $lastItem.trigger($.Event('keydown', {key: 'ArrowDown'}))

      const finalOrder = $('.navitem.enabled')
        .map((i, el) => el.id)
        .get()

      expect(finalOrder).toEqual(initialOrder)
    })
  })

  describe('dropping items', () => {
    it.skip('exits drag mode when space is pressed again', () => {
      const $item = $('.navitem.enabled').eq(1)

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      $item.trigger($.Event('keydown', {key: 'ArrowDown'}))
      vi.clearAllMocks()

      $item.trigger($.Event('keydown', {key: ' '}))

      expect($item.hasClass('dragging')).toBe(false)
      expect($item.attr('aria-grabbed')).toBe('false')
      expect(view.draggedItem).toBeNull()
    })

    it.skip('announces drop to screen readers', () => {
      const $item = $('.navitem.enabled').eq(1)

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      vi.clearAllMocks()

      $item.trigger($.Event('keydown', {key: ' '}))

      expect($.screenReaderFlashMessage).toHaveBeenCalledWith(
        expect.stringContaining('Dropped Modules'),
      )
    })

    it.skip('commits the new position', () => {
      const $item = $('.navitem.enabled').eq(1)

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      $item.trigger($.Event('keydown', {key: 'ArrowDown'}))
      $item.trigger($.Event('keydown', {key: ' '}))

      const $newItems = $('.navitem.enabled')
      expect($newItems.eq(2).attr('id')).toBe('nav_edit_tab_id_1')
    })
  })

  describe('canceling drag', () => {
    it.skip('exits drag mode when escape is pressed', () => {
      const $item = $('.navitem.enabled').eq(1)

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      $item.trigger($.Event('keydown', {key: 'Escape'}))

      expect($item.hasClass('dragging')).toBe(false)
      expect($item.attr('aria-grabbed')).toBe('false')
      expect(view.draggedItem).toBeNull()
    })

    it('returns item to original position', () => {
      const $items = $('.navitem.enabled')
      const $item = $items.eq(1)

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      $item.trigger($.Event('keydown', {key: 'ArrowDown'}))
      $item.trigger($.Event('keydown', {key: 'ArrowDown'}))
      $item.trigger($.Event('keydown', {key: 'Escape'}))

      const $newItems = $('.navitem.enabled')
      expect($newItems.eq(1).attr('id')).toBe('nav_edit_tab_id_1')
    })

    it.skip('announces cancellation to screen readers', () => {
      const $item = $('.navitem.enabled').eq(1)

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      vi.clearAllMocks()

      $item.trigger($.Event('keydown', {key: 'Escape'}))

      expect($.screenReaderFlashMessage).toHaveBeenCalledWith(
        expect.stringContaining('Cancelled move of Modules'),
      )
    })

    it('keeps item in place when canceled without moving', () => {
      const $items = $('.navitem.enabled')
      const $item = $items.eq(1)
      const originalId = $item.attr('id')

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      $item.trigger($.Event('keydown', {key: 'Escape'}))

      const $newItems = $('.navitem.enabled')
      expect($newItems.eq(1).attr('id')).toBe(originalId)
    })

    it('does not trigger escape handler when not in drag mode', () => {
      const $item = $('.navitem.enabled').first()

      $item.focus()
      const event = $.Event('keydown', {key: 'Escape'})
      $item.trigger(event)

      expect(event.isDefaultPrevented()).toBe(false)
    })
  })

  describe('focus and blur handling', () => {
    it('adds keyboard-focus class on focus', () => {
      const $item = $('.navitem.enabled').first()

      $item.trigger('focus')

      expect($item.hasClass('keyboard-focus')).toBe(true)
    })

    it('removes keyboard-focus class on blur', () => {
      const $item = $('.navitem.enabled').first()

      $item.trigger('focus')
      $item.trigger('blur')

      expect($item.hasClass('keyboard-focus')).toBe(false)
    })

    it.skip('does not cancel drag when moving between items', () => {
      const $item = $('.navitem.enabled').eq(1)

      $item.focus()
      $item.trigger($.Event('keydown', {key: ' '}))
      $item.trigger($.Event('keydown', {key: 'ArrowUp'}))

      expect(view.draggedItem).toBeTruthy()
      expect($item.hasClass('dragging')).toBe(true)
    })
  })

  describe('menu interaction', () => {
    it('does not handle arrow keys when focus is inside admin menu', () => {
      const $items = $('.navitem.enabled')
      const $firstItem = $items.eq(0)
      const $secondItem = $items.eq(1)
      const $menuLink = $firstItem.find('.al-options a')

      $firstItem.focus()
      const initialOrder = $('.navitem.enabled')
        .map((i, el) => el.id)
        .get()

      const event = $.Event('keydown', {which: 40, target: $menuLink[0]})
      $firstItem.trigger(event)

      const finalOrder = $('.navitem.enabled')
        .map((i, el) => el.id)
        .get()

      expect(finalOrder).toEqual(initialOrder)
      expect(document.activeElement).not.toBe($secondItem[0])
    })
  })

  describe('disable/enable click handlers', () => {
    it('moves nav item to disabled list when disable is clicked', () => {
      const $item = $('.navitem.enabled').first()
      const itemId = $item.attr('id')
      const $disableLink = $item.find('.al-trigger')

      view.disableNavLink({currentTarget: $disableLink[0]})

      expect($(`#nav_disabled_list #${itemId}`)).toHaveLength(1)
      expect($(`#nav_enabled_list #${itemId}`)).toHaveLength(0)
    })
  })
})
