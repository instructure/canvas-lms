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

import {each} from 'lodash'
import CollectionView from '@canvas/backbone-collection-view'
import WikiPageRevisionView from './WikiPageRevisionView'
import template from '../../jst/WikiPageRevisions.handlebars'
import '../../jquery/floatingSticky'
import {publish} from 'jquery-tinypubsub'

export default class WikiPageRevisionsView extends CollectionView {
  static initClass() {
    this.prototype.className = 'show-revisions'
    this.prototype.template = template
    this.prototype.itemView = WikiPageRevisionView

    this.mixin({
      events: {
        'click .prev-button': 'prevPage',
        'click .next-button': 'nextPage',
        'click .close-button': 'close',
      },
      els: {
        '#ticker': '$ticker',
        aside: '$aside',
        '.revisions-list': '$revisionsList',
      },
    })

    this.optionProperty('pages_path')
  }

  initialize(_options) {
    super.initialize(...arguments)
    this.selectedRevision = null

    // handle selection changes
    this.on('selectionChanged', (newSelection, oldSelection) => {
      if (oldSelection.model != null) {
        oldSelection.model.set('selected', false)
      }
      return newSelection.model != null ? newSelection.model.set('selected', true) : undefined
    })

    // reposition after rendering
    return this.on('render renderItem', () => this.reposition())
  }

  afterRender() {
    super.afterRender(...arguments)
    publish('userContent/change')
    this.trigger('render')

    return (this.floatingSticky = this.$aside.floatingSticky('#main', {top: '#content'}))
  }

  remove() {
    if (this.floatingSticky) {
      each(this.floatingSticky, sticky => sticky.remove())
      this.floatingSticky = null
    }

    return super.remove(...arguments)
  }

  renderItem() {
    super.renderItem(...arguments)
    return this.trigger('renderItem')
  }

  attachItemView(model, view) {
    if (
      !!this.selectedRevision &&
      this.selectedRevision.get('revision_id') === model.get('revision_id')
    ) {
      model.set(this.selectedRevision.attributes)
      model.set('selected', true)
      this.setSelectedModelAndView(model, view)
    } else {
      model.set('selected', false)
    }

    const selectModel = () => {
      return this.setSelectedModelAndView(model, view)
    }
    if (!this.selectedModel) {
      selectModel()
    }

    view.pages_path = this.pages_path
    view.$el.on('click', selectModel)
    return view.$el.on('keypress', e => {
      if (e.keyCode === 13 || e.keyCode === 27) {
        e.preventDefault()
        return selectModel()
      }
    })
  }

  setSelectedModelAndView(model, view) {
    const oldSelectedModel = this.selectedModel
    const oldSelectedView = this.selectedView
    this.selectedModel = model
    this.selectedView = view
    this.selectedRevision = model
    return this.trigger(
      'selectionChanged',
      {model, view},
      {model: oldSelectedModel, view: oldSelectedView}
    )
  }

  reposition() {
    if (this.floatingSticky) {
      each(this.floatingSticky, sticky => sticky.reposition())
    }
  }

  prevPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    return this.$el.disableWhileLoading(this.collection.fetch({page: 'prev', reset: true}))
  }

  nextPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    return this.$el.disableWhileLoading(this.collection.fetch({page: 'next', reset: true}))
  }

  close(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    return (window.location.href = this.collection.parentModel.get('html_url'))
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.CAN = {
      FETCH_PREV: this.collection.canFetch('prev'),
      FETCH_NEXT: this.collection.canFetch('next'),
    }
    return json
  }
}
WikiPageRevisionsView.initClass()
