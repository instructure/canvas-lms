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
import I18n from 'i18n!pages'
import WikiPage from '../../models/WikiPage'
import PaginatedCollectionView from '../PaginatedCollectionView'
import WikiPageEditView from './WikiPageEditView'
import itemView from './WikiPageIndexItemView'
import template from 'jst/wiki/WikiPageIndex'
import StickyHeaderMixin from '../StickyHeaderMixin'
import splitAssetString from '../../str/splitAssetString'
import 'jquery.disableWhileLoading'

export default class WikiPageIndexView extends PaginatedCollectionView {
  static initClass() {
    this.mixin(StickyHeaderMixin)
    this.mixin({
      events: {
        'click .new_page': 'createNewPage',
        'keyclick .new_page': 'createNewPage',
        'click .header-row a[data-sort-field]': 'sort'
      },

      els: {
        '.no-pages': '$noPages',
        '.no-pages a:first-child': '$noPagesLink',
        '.header-row a[data-sort-field]': '$sortHeaders'
      }
    })

    this.prototype.template = template
    this.prototype.itemView = itemView

    this.optionProperty('default_editing_roles')
    this.optionProperty('WIKI_RIGHTS')

    this.lastFocusField = null
  }

  initialize(options) {
    super.initialize(...arguments)
    if (!this.WIKI_RIGHTS) this.WIKI_RIGHTS = {}

    if (!this.itemViewOptions) this.itemViewOptions = {}
    this.itemViewOptions.indexView = this
    this.itemViewOptions.collection = this.collection
    this.itemViewOptions.WIKI_RIGHTS = this.WIKI_RIGHTS
    this.itemViewOptions.collectionHasTodoDate = this.collectionHasTodoDate
    this.focusAfterRenderSelector = null

    this.contextAssetString = options != null ? options.contextAssetString : undefined
    if (this.contextAssetString) {
      ;[this.contextName, this.contextId] = Array.from(splitAssetString(this.contextAssetString))
    }
    this.itemViewOptions.contextName = this.contextName

    this.collection.on('fetch', () => {
      if (!this.fetched) {
        this.fetched = true
        return this.render()
      }
    })
    this.collection.on('fetched:last', () => {
      this.fetchedLast = true
      return this.render()
    })

    this.collection.on('sortChanged', this.sortChanged.bind(this))
    return (this.currentSortField = this.collection.currentSortField)
  }

  afterRender() {
    super.afterRender(...arguments)
    this.$noPages.redirectClickTo(this.$noPagesLink)
    this.renderSortHeaders()
    if (this.focusAfterRenderSelector) {
      // We do a setTimeout here just to force it to the next tick.
      return setTimeout(() => {
        $(this.focusAfterRenderSelector).focus()
      }, 1)
    }
  }

  sort(event = {}) {
    let sortField, sortOrder
    event.preventDefault()
    this.lastFocusField = sortField = $(event.currentTarget).data('sort-field')
    if (!this.currentSortField) {
      sortOrder = this.collection.sortOrders[sortField]
    }
    return this.$el.disableWhileLoading(this.collection.sortByField(sortField, sortOrder))
  }

  sortChanged(currentSortField) {
    this.currentSortField = currentSortField
    return this.renderSortHeaders()
  }

  renderSortHeaders() {
    if (!this.$sortHeaders) return

    const {sortOrders} = this.collection
    for (let sortHeader of Array.from(this.$sortHeaders)) {
      const $sortHeader = $(sortHeader)
      const $i = $sortHeader.find('i')

      const sortField = $sortHeader.data('sort-field')
      const sortOrder = sortOrders[sortField] === 'asc' ? 'up' : 'down'

      if (sortOrder === 'up') {
        $sortHeader.attr(
          'aria-label',
          I18n.t('headers.sort_ascending', '%{title}, Sort ascending', {title: $sortHeader.text()})
        )
      } else {
        $sortHeader.attr(
          'aria-label',
          I18n.t('headers.sort_descending', '%{title}, Sort descending', {
            title: $sortHeader.text()
          })
        )
      }

      $sortHeader.toggleClass('sort-field-active', sortField === this.currentSortField)
      $i.removeClass('icon-mini-arrow-up icon-mini-arrow-down')
      $i.addClass(`icon-mini-arrow-${sortOrder}`)
    }

    if (this.lastFocusField) {
      $(`[data-sort-field='${this.lastFocusField}']`).focus()
    }
  }

  createNewPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }

    this.$el.hide()
    $('body').removeClass('index')
    $('body').addClass('edit with-right-side')

    this.editModel = new WikiPage(
      {editing_roles: this.default_editing_roles},
      {contextAssetString: this.contextAssetString}
    )
    this.editView = new WikiPageEditView({
      model: this.editModel,
      wiki_pages_path: ENV.WIKI_PAGES_PATH,
      WIKI_RIGHTS: ENV.WIKI_RIGHTS,
      PAGE_RIGHTS: {
        update: ENV.WIKI_RIGHTS.update_page,
        update_content: ENV.WIKI_RIGHTS.update_page_content,
        read_revisions: ENV.WIKI_RIGHTS.read_revisions
      }
    })
    this.$el.parent().append(this.editView.$el)

    this.editView.render()

    // override the cancel behavior
    return this.editView.on('cancel', () => {
      this.editView.destroyEditor()
      $('body').removeClass('edit with-right-side')
      $('body').addClass('index')
      return this.$el.show()
    })
  }

  collectionHasTodoDate() {
    if (!ENV.STUDENT_PLANNER_ENABLED) {
      return false
    }
    return !!this.collection.find(m => m.has('todo_date'))
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.CAN = {
      CREATE: !!this.WIKI_RIGHTS.create_page,
      MANAGE: !!this.WIKI_RIGHTS.manage,
      PUBLISH: !!this.WIKI_RIGHTS.manage && this.contextName === 'courses'
    }
    json.CAN.VIEW_TOOLBAR = json.CAN.CREATE
    json.fetched = !!this.fetched
    json.fetchedLast = !!this.fetchedLast
    json.collectionHasTodoDate = this.collectionHasTodoDate()
    return json
  }
}
WikiPageIndexView.initClass()
