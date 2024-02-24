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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import WikiPageIndexEditDialog from './WikiPageIndexEditDialog'
import WikiPageDeleteDialog from '@canvas/wiki/backbone/views/WikiPageDeleteDialog'
import PublishIconView from '@canvas/publish-icon-view'
import LockIconView from '@canvas/lock-icon'
import template from '../../jst/WikiPageIndexItem.handlebars'
import '../../jquery/redirectClickTo'
import {renderFrontPagePill} from '@canvas/wiki/react/renderFrontPagePill'

const I18n = useI18nScope('pages')

export default class WikiPageIndexItemView extends Backbone.View {
  static initClass() {
    this.prototype.template = template
    this.prototype.tagName = 'tr'
    this.prototype.className = 'clickable'
    this.prototype.attributes = {role: 'row'}
    this.prototype.els = {
      '.wiki-page-link': '$wikiPageLink',
      '.publish-cell': '$publishCell',
      '.master-content-lock-cell': '$lockCell',
      'a.al-trigger': '$settingsMenu',
    }
    this.prototype.events = {
      'click a.al-trigger': 'settingsMenu',
      'click .edit-menu-item': 'editPage',
      'click .delete-menu-item': 'deletePage',
      'click .use-as-front-page-menu-item': 'useAsFrontPage',
      'click .unset-as-front-page-menu-item': 'unsetAsFrontPage',
      'click .duplicate-wiki-page': 'duplicateWikiPage',
      'click .send-wiki-page-to': 'sendWikiPageTo',
      'click .copy-wiki-page-to': 'copyWikiPageTo',
      'change .select-page-checkbox': 'changeSelectPageCheckbox',
    }

    this.optionProperty('indexView')
    this.optionProperty('collection')
    this.optionProperty('WIKI_RIGHTS')
    this.optionProperty('contextName')
    this.optionProperty('selectedPages')
    this.optionProperty('collectionHasTodoDate')
  }

  initialize() {
    super.initialize(...arguments)
    if (!this.WIKI_RIGHTS) this.WIKI_RIGHTS = {}
    this.model.set('unpublishable', true)
    return this.model.on('change', () => this.render())
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.CAN = {
      MANAGE:
        !!this.WIKI_RIGHTS.create_page ||
        !!this.WIKI_RIGHTS.delete_page ||
        !!this.WIKI_RIGHTS.publish_page ||
        !!this.WIKI_RIGHTS.update,
      PUBLISH: !!this.WIKI_RIGHTS.publish_page,
      DUPLICATE: !!this.WIKI_RIGHTS.create_page && this.contextName === 'courses',
      UPDATE: !!this.WIKI_RIGHTS.update,
      DELETE: !!this.WIKI_RIGHTS.delete_page,
    }

    json.DIRECT_SHARE_ENABLED = ENV.DIRECT_SHARE_ENABLED
    // NOTE: if permissions need to change for OPEN_MANAGE_OPTIONS, please update WikiPageIndexView.js to match
    json.CAN.OPEN_MANAGE_OPTIONS = json.CAN.MANAGE || json.DIRECT_SHARE_ENABLED

    if (json.is_master_course_child_content && json.restricted_by_master_course) {
      json.cannot_delete_by_master_course = true
      json.cannot_edit_by_master_course = json.master_course_restrictions.content
    }

    json.wiki_page_menu_tools = ENV.wiki_page_menu_tools || []
    json.wiki_page_menu_tools.forEach(tool => {
      return (tool.url = tool.base_url + `&pages[]=${this.model.get('page_id')}`)
    })
    json.isChecked = this.selectedPages.hasOwnProperty(this.model.get('page_id'))
    json.collectionHasTodoDate = this.collectionHasTodoDate()
    json.frontPageText = ENV.K5_SUBJECT_COURSE ? I18n.t('Subject Home') : I18n.t('Front Page')
    return json
  }

  render() {
    // detach the icons to preserve data/events
    if (this.publishIconView != null) {
      this.publishIconView.$el.detach()
    }
    if (this.lockIconView != null) {
      this.lockIconView.$el.detach()
    }

    super.render(...arguments)
    renderFrontPagePill(this.$el[0], {children: this.toJSON().frontPageText})
    this.changeSelectPageCheckbox()

    // attach/re-attach the icons
    if (!this.publishIconView) {
      this.publishIconView = new PublishIconView({
        model: this.model,
        title: this.model.get('title'),
      })
      this.model.view = this
    }
    this.publishIconView.$el.appendTo(this.$publishCell)
    this.publishIconView.render()

    if (!this.lockIconView) {
      this.lockIconView = new LockIconView({
        model: this.model,
        unlockedText: I18n.t('%{name} is unlocked. Click to lock.', {
          name: this.model.get('title'),
        }),
        lockedText: I18n.t('%{name} is locked. Click to unlock.', {name: this.model.get('title')}),
        course_id: ENV.COURSE_ID,
        content_id: this.model.get('page_id'),
        content_type: 'wiki_page',
      })
      this.model.view = this
    }
    this.lockIconView.$el.appendTo(this.$lockCell)
    return this.lockIconView.render()
  }

  afterRender() {
    return this.$el.find("td:not('.not_clickable'):first").redirectClickTo(this.$wikiPageLink)
  }

  settingsMenu(ev) {
    return ev != null ? ev.preventDefault() : undefined
  }

  editPage(ev = {}) {
    ev.preventDefault()

    const $curCog = $(ev.target).parents('td').children().find('.al-trigger')

    const editDialog = new WikiPageIndexEditDialog({
      model: this.model,
      returnFocusTo: $curCog,
    })
    editDialog.open()

    const {indexView} = this
    const {collection} = this
    return editDialog.on('success', function () {
      indexView.focusAfterRenderSelector = `a#${this.model.get('page_id')}-menu.al-trigger`
      indexView.currentSortField = null
      indexView.renderSortHeaders()

      return collection.fetch({page: 'current'})
    })
  }

  deletePage(ev = {}) {
    let $focusOnDelete
    ev.preventDefault()

    if (!this.model.get('deletable')) return

    const $curCog = $(ev.target).parents('td').children().find('.al-trigger')
    const $allCogs = $('.collectionViewItems').children().find('.al-trigger')
    const curIndex = $allCogs.index($curCog)
    const newIndex = curIndex - 1
    if (newIndex < 0) {
      // We were at the top, or there wasn't another page item cog
      $focusOnDelete = $('.new_page')
    } else {
      const $allTitles = $('.collectionViewItems').children().find('.wiki-page-link')
      $focusOnDelete = $allTitles[newIndex]
    }

    const deleteDialog = new WikiPageDeleteDialog({
      model: this.model,
      focusOnCancel: $curCog,
      onDelete: () => {
        $focusOnDelete.focus()
        delete this.selectedPages[this.model.id]
        this.changeSelectPageCheckbox()
      },
    })
    return deleteDialog.open()
  }

  duplicateWikiPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    const {collection} = this
    const {model} = this

    function handleResponse(response) {
      const placeToAdd = collection.indexOf(model) + 1
      collection.add(response, {at: placeToAdd})
      $(`#wiki_page_index_item_title_${response.page_id}`).focus()
    }

    this.model.duplicate(ENV.COURSE_ID, handleResponse)
  }

  unsetAsFrontPage(ev) {
    let curIndex
    if (ev != null) {
      ev.preventDefault()
    }

    if (ev != null ? ev.target : undefined) {
      const $curCog = $(ev.target).parents('td').children().find('.al-trigger')
      const $allCogs = $('.collectionViewItems').children().find('.al-trigger')
      curIndex = $allCogs.index($curCog)
    }

    return this.model.unsetFrontPage(() => {
      // Here's the aforementioned magic and index stuff
      if (curIndex != null) {
        const cogs = $('.collectionViewItems').children().find('.al-trigger')
        $(cogs[curIndex]).focus()
      }
    })
  }

  useAsFrontPage(ev) {
    let curIndex
    if (ev != null) {
      ev.preventDefault()
    }
    if (!this.model.get('published')) return
    // This bit of magic has to happen this way because the $curCog
    // isn't valid after the re-render occurs... so we use the index and
    // re-collect the cogs afterwards.
    if (ev != null ? ev.target : undefined) {
      const $curCog = $(ev.target).parents('td').find('.al-trigger')
      const $allCogs = $('.collectionViewItems').find('.al-trigger')
      curIndex = $allCogs.index($curCog)
    }

    return this.model.setFrontPage(() => {
      // Here's the aforementioned magic and index stuff
      if (curIndex != null) {
        const cogs = $('.collectionViewItems').find('.al-trigger')
        $(cogs[curIndex]).focus()
      }
      delete this.selectedPages[this.model.id]
      this.changeSelectPageCheckbox()
    })
  }

  sendWikiPageTo(ev) {
    ev.preventDefault()
    this.indexView.setSendToItem(this.model, this.$settingsMenu)
  }

  copyWikiPageTo(ev) {
    ev.preventDefault()
    this.indexView.setCopyToItem(this.model, this.$settingsMenu)
  }

  changeSelectPageCheckbox(ev) {
    if (ev) {
      ev.preventDefault()
      const {checked} = ev.target
      const pageId = this.model.get('page_id')
      if (checked) {
        this.selectedPages[pageId] = this.model
      } else {
        delete this.selectedPages[pageId]
      }
    }
    $('.delete_pages').prop('disabled', Object.keys(this.selectedPages).length === 0)
  }
}
WikiPageIndexItemView.initClass()
