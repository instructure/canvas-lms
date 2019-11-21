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
import React from 'react'
import ReactDOM from 'react-dom'
import I18n from 'i18n!pages'
import WikiPage from '../../models/WikiPage'
import PaginatedCollectionView from '../PaginatedCollectionView'
import WikiPageEditView from './WikiPageEditView'
import itemView from './WikiPageIndexItemView'
import template from 'jst/wiki/WikiPageIndex'
import StickyHeaderMixin from '../StickyHeaderMixin'
import splitAssetString from '../../str/splitAssetString'
import ContentTypeExternalToolTray from 'jsx/shared/ContentTypeExternalToolTray'
import DirectShareCourseTray from 'jsx/shared/direct_share/DirectShareCourseTray'
import DirectShareUserModal from 'jsx/shared/direct_share/DirectShareUserModal'
import 'jquery.disableWhileLoading'
import {ltiState} from '../../../../public/javascripts/lti/post_message/handleLtiPostMessage'

export default class WikiPageIndexView extends PaginatedCollectionView {
  static initClass() {
    this.mixin(StickyHeaderMixin)
    this.mixin({
      events: {
        'click .new_page': 'createNewPage',
        'keyclick .new_page': 'createNewPage',
        'click .header-row a[data-sort-field]': 'sort',
        'click .header-bar-right .menu_tool_link': 'openExternalTool'
      },

      els: {
        '.no-pages': '$noPages',
        '.no-pages a:first-child': '$noPagesLink',
        '.header-row a[data-sort-field]': '$sortHeaders',
        '#external-tool-mount-point': '$externalToolMountPoint',
        '#copy-to-mount-point': '$copyToMountPoint',
        '#send-to-mount-point': '$sendToMountPoint'
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

    // Poor man's dependency injection just so we can stub out the react components
    this.DirectShareCourseTray = DirectShareCourseTray
    this.DirectShareUserModal = DirectShareUserModal
    this.ContentTypeExternalToolTray = ContentTypeExternalToolTray

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

    this.wikiIndexPlacements = options != null ? options.wikiIndexPlacements : []
    if (!this.wikiIndexPlacements) this.wikiIndexPlacements = []

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
    for (const sortHeader of Array.from(this.$sortHeaders)) {
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
    $('body').addClass(`edit ${window.ENV.use_rce_enhancements ? '' : 'with-right-side'}`)

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

  openExternalTool(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    const tool = this.wikiIndexPlacements.find(t => t.id === ev.target.dataset.toolId)
    this.setExternalToolTray(tool, $('.al-trigger')[0])
  }

  reloadPage() {
    window.location.reload()
  }

  setExternalToolTray(tool, returnFocusTo) {
    const handleDismiss = () => {
      this.setExternalToolTray(null)
      returnFocusTo.focus()
      if (ltiState?.tray?.refreshOnClose) {
        this.reloadPage()
      }
    }

    const {ContentTypeExternalToolTray: ExternalToolTray} = this
    ReactDOM.render(
      <ExternalToolTray
        tool={tool}
        placement="wiki_index_menu"
        acceptedResourceTypes={['page']}
        targetResourceType="page"
        allowItemSelection={false}
        selectableItems={[]}
        onDismiss={handleDismiss}
        open={tool !== null}
      />,
      this.$externalToolMountPoint[0]
    )
  }

  setCopyToItem(newCopyToItem, returnFocusTo) {
    const handleDismiss = () => {
      this.setCopyToItem(null)
      returnFocusTo.focus()
    }

    const pageId = newCopyToItem?.id
    const {DirectShareCourseTray: CourseTray} = this
    ReactDOM.render(
      <CourseTray
        open={newCopyToItem !== null}
        sourceCourseId={ENV.COURSE_ID}
        contentSelection={{pages: [pageId]}}
        shouldReturnFocus={false}
        onDismiss={handleDismiss}
      />,
      this.$copyToMountPoint[0]
    )
  }

  setSendToItem(newSendToItem, returnFocusTo) {
    const handleDismiss = () => {
      this.setSendToItem(null)
      // focus still gets mucked up even with shouldReturnFocus={false}, so set it later.
      setTimeout(() => returnFocusTo.focus(), 100)
    }

    const pageId = newSendToItem?.id
    const {DirectShareUserModal: UserModal} = this
    ReactDOM.render(
      <UserModal
        open={newSendToItem !== null}
        courseId={ENV.COURSE_ID}
        contentShare={{content_type: 'page', content_id: pageId}}
        shouldReturnFocus={false}
        onDismiss={handleDismiss}
      />,
      this.$sendToMountPoint[0]
    )
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
    json.hasWikiIndexPlacements = this.wikiIndexPlacements.length > 0
    json.wikiIndexPlacements = this.wikiIndexPlacements
    return json
  }
}
WikiPageIndexView.initClass()
