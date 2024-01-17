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

import {without, sortedIndexOf, find} from 'lodash'
import flattenObjects from '@canvas/util/flattenObjects'
import $ from 'jquery'
import pageNavTemplate from '../../jst/pageNav.handlebars'
import Backbone from '@canvas/backbone'
import EntryCollectionView from './EntryCollectionView'
import 'jquery-scroll-into-view'

export default class EntriesView extends Backbone.View {
  static initClass() {
    this.prototype.defaults = {
      initialPage: 0,
      descendants: 2,
      showMoreDescendants: 50,
      children: 3,
    }

    this.prototype.$window = $(window)

    this.prototype.events = {keydown: 'handleKeyDown'}
  }

  initialize() {
    super.initialize(...arguments)
    this.collection.on('add', this.addEntry, this)
    return this.model.on('change', this.hideIfFiltering, this)
  }

  showDeleted(show) {
    return this.$el.toggleClass('show-deleted', show)
  }

  hideIfFiltering() {
    if (this.model.hasFilter()) {
      return this.$el.addClass('hidden')
    } else {
      return this.$el.removeClass('hidden')
    }
  }

  addEntry(entry) {
    return this.collectionView.collection.add(entry)
  }

  goToEntry(id) {
    // can take an id or an entry object so we don't have to get the entry
    // data when we're trying again
    let entryData
    if (typeof id === 'object') {
      entryData = id
      ;({id} = entryData.entry)
    }
    // dom is the fastest access to see if the entry is already rendered
    const $el = $(`#entry-${id}`)
    if ($el.length) {
      return this.scrollToEl($el)
    }
    if (entryData == null) entryData = this.collection.getEntryData(id)
    if (this.collection.currentPage === entryData.page) {
      if (entryData.levels === 0) {
        return this.expandToUnrenderedEntry(entryData)
      } else {
        return this.descendToUnrenderedEntry(entryData)
      }
    } else {
      return this.renderAndGoToEntry(entryData)
    }
  }

  expandToUnrenderedEntry(entryData) {
    let {entry} = entryData
    let $el = {}
    while (!$el.length) {
      entry = entry.parent
      $el = $(`#entry-${entry.id}`)
    }
    const view = $el.data('view')
    if (view.treeView) {
      view.treeView.loadNext()
    } else {
      view.renderTree()
    }
    // try again, will do this as many times as it takes
    return this.goToEntry(entryData)
  }

  // #
  // finds the last rendered parent, re-orders the parents to be the first
  // child, renders the tree down to the entry
  descendToUnrenderedEntry(entryData) {
    const {entry} = entryData
    let parent = entry
    let descendants = -1
    let $el = {}
    // look for last rendered parent
    while (!$el.length) {
      const child = parent
      ;({parent} = child)
      descendants++
      // put the child on top so we can easily render it
      const replies = without(parent.replies, child)
      replies.unshift(child)
      parent.replies = replies
      // see if its rendered
      $el = $(`#entry-${child.id}`)
    }
    const view = $el.data('view')
    view.renderTree({descendants})
    // try again
    return this.goToEntry(entryData)
  }

  renderAndGoToEntry(entryData) {
    this.render(entryData.page + 1)
    // try again
    return this.goToEntry(entryData)
  }

  scrollToEl($el) {
    return this.$window.scrollTo($el, 200, {
      offset: -150,
      onAfter: () => {
        $el.find('.discussion-title a').first().focus()
        // pretty blinking
        setTimeout(() => $el.addClass('highlight'), 200)
        setTimeout(() => $el.removeClass('highlight'), 400)
        setTimeout(() => $el.addClass('highlight'), 600)
        const once = () => {
          $el.removeClass('highlight')
          this.$window.off('scroll', once)
          return this.trigger('scrollAwayFromEntry')
        }
        // behind setTimeout because onAfter doesn't seem to work properly,
        // and triggers the scroll event we're adding here
        return setTimeout(() => {
          this.$window.on('scroll', once)
          return setTimeout(once, 5000)
        }, 10)
      },
    })
  }

  // #
  // Render a specific page with `page: n`
  render(page = 1) {
    this.teardown()
    this.collectionView = new EntryCollectionView({
      el: this.$el[0],
      collection: this.collection.getPageAsCollection(page - 1, {perPage: this.options.children}),
      descendants: this.options.descendants,
      showMoreDescendants: this.options.showMoreDescendants,
      displayShowMore: false,
      threaded: this.options.threaded,
      root: true,
      collapsed: this.model.get('collapsed'),
    })
    this.collectionView.render()
    this.renderPageNav()
    return this
  }

  teardown() {
    return this.$el.empty()
  }

  renderPageNav() {
    const total = this.collection.totalPages()
    const current = this.collection.currentPage + 1
    if (total < 2) return
    const pagesToShow = 3
    const locals = {current}
    locals.showFirst = total > pagesToShow && current !== 1
    if (total > pagesToShow && current !== total) locals.lastPage = total
    locals.pages = (() => {
      if (total < pagesToShow + 1) {
        return __range__(1, total, true)
      } else if (locals.showFirst && locals.lastPage) {
        return [current - 1, current, current + 1]
      } else if (locals.showFirst && !locals.lastPage) {
        return [current - 2, current - 1, current]
      } else if (!locals.showFirst && locals.lastPage) {
        return [current, current + 1, current + 2]
      }
    })()
    const html = pageNavTemplate(locals)
    return this.$el.prepend(html).append(html)
  }

  handleKeyDown(e) {
    const nodeName = e.target.nodeName.toLowerCase()
    if (nodeName === 'input' || nodeName === 'textarea' || ENV.disable_keyboard_shortcuts) return
    if (e.which !== 74 && e.which !== 75) return // j, k
    const entry = $(e.target).closest('.entry')
    this.traverse(entry, e.which === 75)
    e.preventDefault()
    return e.stopPropagation()
  }

  traverse(el, reverse) {
    const id = el.attr('id').replace('entry-', '')

    const json = this.collection.toJSON()
    // sub-collections are displayed in reverse when flat, in imitation of Facebook
    const list = flattenObjects(json, 'replies', !this.options.threaded)
    const entry = find(list, x => `${x.id}` === id)
    let pos = sortedIndexOf(list, entry)
    pos += reverse ? -1 : 1
    pos = Math.min(Math.max(0, pos), list.length - 1)
    const next = list[pos]
    return this.goToEntry(next.id)
  }
}
EntriesView.initClass()

function __range__(left, right, inclusive) {
  const range = []
  const ascending = left < right
  const end = !inclusive ? right : ascending ? right + 1 : right - 1
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i)
  }
  return range
}
