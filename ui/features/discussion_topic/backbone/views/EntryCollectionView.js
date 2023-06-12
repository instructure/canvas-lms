/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import walk from '../../array-walk'
import {View} from '@canvas/backbone'
import {isRTL} from '@canvas/i18n/rtlHelper'
import template from '../../jst/EntryCollectionView.handlebars'
import entryStatsTemplate from '../../jst/entryStats.handlebars'
import EntryView from './EntryView'
import 'jquery-scroll-into-view'

const I18n = useI18nScope('discussions')

extend(EntryCollectionView, View)

function EntryCollectionView() {
  return EntryCollectionView.__super__.constructor.apply(this, arguments)
}

EntryCollectionView.prototype.defaults = {
  descendants: 2,
  showMoreDescendants: 2,
  showReplyButton: false,
  displayShowMore: true,
  // maybe make a sub-class for threaded discussions if the branching gets
  // out of control. UPDATE: it is out of control
  threaded: false,
  // its collection represents the root of the discussion, should probably
  // be a subclass instead :\
  root: false,
}

EntryCollectionView.prototype.events = {
  'click .loadNext': 'loadNextFromEvent',
}

EntryCollectionView.prototype.template = template

EntryCollectionView.prototype.$window = $(window)

EntryCollectionView.prototype.els = {
  '.discussion-entries': 'list',
}

EntryCollectionView.prototype.initialize = function () {
  EntryCollectionView.__super__.initialize.apply(this, arguments)
  return (this.childViews = [])
}

EntryCollectionView.prototype.attach = function () {
  this.collection.on('reset', this.addAll, this)
  return this.collection.on('add', this.add, this)
}

EntryCollectionView.prototype.toJSON = function () {
  return this.options
}

EntryCollectionView.prototype.addAll = function () {
  this.teardown()
  return this.collection.each(this.add.bind(this))
}

EntryCollectionView.prototype.add = function (entry) {
  const view = new EntryView({
    model: entry,
    treeView: this.constructor,
    descendants: this.options.descendants,
    children: this.collection.options.perPage,
    showMoreDescendants: this.options.showMoreDescendants,
    threaded: this.options.threaded,
    collapsed: this.options.collapsed,
  })
  view.render()
  entry.on('change:editor', this.nestEntries)
  if (entry.get('new')) {
    return this.addNewView(view)
  }
  if (this.options.descendants) {
    view.renderTree()
  } else if (entry.hasChildren()) {
    view.renderDescendantsLink()
  }
  if (!this.options.threaded && !this.options.root) {
    this.list.prepend(view.el)
  } else {
    this.list.append(view.el)
  }
  this.childViews.push(view)
  return this.nestEntries()
}

EntryCollectionView.prototype.nestEntries = function () {
  const directionToPad = isRTL() ? 'right' : 'left'
  return $('.entry-content[data-should-position]').each(function () {
    const $el = $(this)
    const level = $el.parents('li.entry').length
    const offset = (level - 1) * 30
    $el.css('padding-' + directionToPad, offset).removeAttr('data-should-position')
    return $el.find('.discussion-title').attr({
      role: 'heading',
      'aria-level': level + 1,
    })
  })
}

EntryCollectionView.prototype.addNewView = function (view) {
  view.model.set('new', false)
  this.list.append(view.el)
  this.nestEntries()
  if (!this.options.root) {
    this.$window.scrollTo(view.$el, 200)
    view.$el.hide()
    return setTimeout(
      (function (_this) {
        return function () {
          return view.$el.fadeIn()
        }
      })(this),
      500
    )
  }
}

EntryCollectionView.prototype.teardown = function () {
  return this.list.empty()
}

EntryCollectionView.prototype.afterRender = function () {
  EntryCollectionView.__super__.afterRender.apply(this, arguments)
  this.addAll()
  return this.renderNextLink()
}

EntryCollectionView.prototype.renderNextLink = function () {
  let moreText, ref
  if ((ref = this.nextLink) != null) {
    ref.remove()
  }
  if (!(this.options.displayShowMore && this.unShownChildren() > 0)) {
    return
  }
  const stats = this.getUnshownStats()
  this.nextLink = $('<div/>')
  if (!this.options.threaded) {
    moreText = I18n.t(
      'show_all_n_replies',
      {
        one: 'Show one reply',
        other: 'Show all %{count} replies',
      },
      {
        count: stats.total + this.collection.options.perPage,
      }
    )
  }
  this.nextLink.html(
    entryStatsTemplate({
      stats,
      moreText,
      showMore: true,
    })
  )
  this.nextLink.addClass('showMore loadNext')
  if (this.options.threaded) {
    return this.nextLink.insertAfter(this.list)
  } else {
    return this.nextLink.insertBefore(this.list)
  }
}

EntryCollectionView.prototype.getUnshownStats = function () {
  const start = this.collection.length
  const end = this.collection.fullCollection.length
  const unshown = this.collection.fullCollection.toJSON().slice(start, end)
  let total = 0
  let unread = 0
  // No need to recursively traverse unshown here as
  // the collection has already been flattened. Using
  // undefined as the prop prevents the recursive walk
  walk(unshown, void 0, function (entry) {
    total++
    if (entry.read_state === 'unread') {
      return unread++
    }
  })
  return {
    total,
    unread,
  }
}

EntryCollectionView.prototype.unShownChildren = function () {
  return this.collection.fullCollection.length - this.collection.length
}

EntryCollectionView.prototype.loadNextFromEvent = function (event) {
  event.stopPropagation()
  event.preventDefault()
  return this.loadNext()
}

EntryCollectionView.prototype.loadNext = function () {
  if (this.options.threaded) {
    this.collection.add(this.collection.fullCollection.getPage('next'))
  } else {
    this.collection.reset(this.collection.fullCollection.toArray())
  }
  return this.renderNextLink()
}

EntryCollectionView.prototype.filter = EntryCollectionView.prototype.afterRender

export default EntryCollectionView
