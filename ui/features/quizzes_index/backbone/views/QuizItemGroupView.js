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
import {filter} from 'lodash'
import CollectionView from '@canvas/backbone-collection-view'
import template from '../../jst/QuizItemGroupView.handlebars'
import QuizItemView from './QuizItemView'

export default class ItemGroupView extends CollectionView {
  static initClass() {
    this.prototype.template = template
    this.prototype.itemView = QuizItemView

    this.prototype.tagName = 'div'
    this.prototype.className = 'item-group-condensed'

    this.prototype.events = {'click .ig-header .element_toggler': 'clickHeader'}
  }

  clickHeader(e) {
    $(e.currentTarget)
      .find('i')
      .toggleClass('icon-mini-arrow-down')
      .toggleClass('icon-mini-arrow-right')
  }

  isEmpty() {
    return this.collection.isEmpty() || this.collection.all(m => m.get('hidden'))
  }

  filterResults(term) {
    let anyChanged = false
    this.collection.forEach(model => {
      const hidden = !this.filter(model, term)
      if (!!model.get('hidden') !== hidden) {
        anyChanged = true
        return model.set('hidden', hidden)
      }
    })
    if (anyChanged) {
      return this.render()
    }
  }

  matchingCount(term) {
    return filter(this.collection.models, m => {
      return this.filter(m, term)
    }).length
  }

  filter(model, term) {
    if (!term) {
      return true
    }

    const title = model.get('title').toLowerCase()
    let numMatches = 0
    const keys = term.toLowerCase().split(' ')
    for (const part of keys) {
      // not using match to avoid javascript string to regex oddness
      if (title.indexOf(part) !== -1) {
        numMatches++
      }
    }
    return numMatches === keys.length
  }

  render() {
    super.render(...arguments)
    this.$el.find('.no_content').toggle(this.isEmpty())
    return this
  }

  renderItem(model) {
    if (model.get('hidden')) return
    return super.renderItem(...arguments)
  }
}
ItemGroupView.initClass()
