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

import noResultsTemplate from '../../jst/noResults.handlebars'
import $ from 'jquery'
import {filter} from 'lodash'
import FilterEntryView from './FilterEntryView'
import EntryCollectionView from './EntryCollectionView'
import EntryCollection from '../collections/EntryCollection'
import rEscape from '@canvas/escape-regex'

export default class DiscussionFilterResultsView extends EntryCollectionView {
  static initClass() {
    this.prototype.defaults = {
      ...EntryCollectionView.prototype.defaults,
      descendants: 0,
      displayShowMore: true,
      threaded: true,
    }
  }

  initialize() {
    super.initialize(...arguments)
    return (this.allData = this.options.allData)
  }

  attach() {
    return this.model.on('change', this.renderOrTeardownResults, this)
  }

  setAllReadState(newReadState) {
    if (this.collection != null) {
      return this.collection.fullCollection.each(entry => entry.set('read_state', newReadState))
    }
  }

  resetCollection(models) {
    const collection = new EntryCollection(models, {perPage: 10})
    this.collection = collection.getPageAsCollection(0)
    this.collection.on('add', this.add, this)
    this.render()
    // sync read_state changes between @collection and @allData materialized view
    return this.collection.on('change:read_state', (entry, read_state) => {
      this.trigger('readStateChanged', entry.id, read_state)
      // check if rendered entry exists to visually update
      const $el = $(`#entry-${entry.id}`)
      if ($el.length) {
        entry = $el.data('view').model
        if (entry) return entry.set('read_state', read_state)
      }
    })
  }

  add(entry) {
    const view = new FilterEntryView({model: entry})
    view.render()
    view.on('click', () => {
      this.clearModel()
      return setTimeout(() => this.trigger('clickEntry', view.model), 1)
    })
    return this.list.append(view.el)
  }

  toggleRead(e) {
    e.preventDefault()
    if (this.model.get('read_state') === 'read') {
      return this.model.markAsUnread()
    } else {
      return this.model.markAsRead()
    }
  }

  clearModel() {
    return this.model.reset()
  }

  render() {
    if (this.collection != null) super.render(...arguments)
    this.trigger('render')
    return this.$el.removeClass('hidden')
  }

  renderOrTeardownResults() {
    if (this.model.hasFilter()) {
      let results = (() => {
        const result = []
        for (const id in this.allData.flattened) {
          const entry = this.allData.flattened[id]
          result.push(entry)
        }
        return result
      })()
      const object = this.model.toJSON()
      for (const filter in object) {
        const value = object[filter]
        const filterFn = this[`${filter}Filter`]
        if (filterFn) results = filterFn(value, results)
      }
      if (results.length) {
        return this.resetCollection(results)
      } else {
        return this.renderNoResults()
      }
    } else if (!this.model.hasFilter()) {
      this.$el.addClass('hidden')
      return this.trigger('hide')
    }
  }

  renderNoResults() {
    this.render()
    return this.$el.html(noResultsTemplate)
  }

  unreadFilter(unread, results) {
    if (!unread) return results
    unread = filter(results, entry => entry.read_state === 'unread')
    return unread.sort((a, b) => Date.parse(a.created_at) - Date.parse(b.created_at))
  }

  queryFilter(query, results) {
    const regexps = (query != null ? query : '')
      .trim()
      .split(/\s+/g)
      .map(word => new RegExp(rEscape(word), 'i'))
    if (!regexps.length) return results
    return filter(results, entry => {
      if (entry.deleted) return false
      const concat = `\
${entry.message}
${entry.author.display_name}\
`
      for (const regexp of regexps) {
        if (!regexp.test(concat)) return false
      }
      return true
    })
  }
}
DiscussionFilterResultsView.initClass()
