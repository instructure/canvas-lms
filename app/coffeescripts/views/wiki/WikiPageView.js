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
import tz from 'timezone'
import _ from 'underscore'
import Backbone from 'Backbone'
import template from 'jst/wiki/WikiPage'
import StickyHeaderMixin from '../StickyHeaderMixin'
import WikiPageDeleteDialog from './WikiPageDeleteDialog'
import WikiPageReloadView from './WikiPageReloadView'
import PublishButtonView from '../PublishButtonView'
import I18n from 'i18n!pages'
import htmlEscape from 'str/htmlEscape'
import 'prerequisites_lookup'
import 'content_locks'

export default class WikiPageView extends Backbone.View {
  static initClass() {
    this.mixin(StickyHeaderMixin)

    this.prototype.template = template

    this.prototype.els = {
      '.publish-button': '$publishButton',
      '.header-bar-outer-container': '$headerBarOuterContainer',
      '.page-changed-alert': '$pageChangedAlert'
    }

    this.prototype.events = {
      'click .delete_page': 'deleteWikiPage',
      'click .use-as-front-page-menu-item': 'useAsFrontPage',
      'click .unset-as-front-page-menu-item': 'unsetAsFrontPage'
    }

    this.optionProperty('modules_path')
    this.optionProperty('wiki_pages_path')
    this.optionProperty('wiki_page_edit_path')
    this.optionProperty('wiki_page_history_path')
    this.optionProperty('WIKI_RIGHTS')
    this.optionProperty('PAGE_RIGHTS')
    this.optionProperty('course_id')
    this.optionProperty('course_home')
    this.optionProperty('course_title')
    this.optionProperty('display_show_all_pages')
  }

  initialize() {
    this.model.on('change', () => this.render())
    super.initialize(...arguments)
    if (!this.WIKI_RIGHTS) this.WIKI_RIGHTS = {}
    return this.PAGE_RIGHTS || (this.PAGE_RIGHTS = {})
  }

  render() {
    // detach elements to preserve data/events
    if (this.publishButtonView != null) {
      this.publishButtonView.$el.detach()
    }
    if (this.$sequenceFooter != null) {
      this.$sequenceFooter.detach()
    }

    super.render(...arguments)

    if (this.model.get('locked_for_user')) {
      const lock_info = this.model.get('lock_info')
      $('.lock_explanation').html(htmlEscape(INST.lockExplanation(lock_info, 'page')))
      if (lock_info.context_module && lock_info.context_module.id) {
        const prerequisites_lookup = `${ENV.MODULES_PATH}/${
          lock_info.context_module.id
        }/prerequisites/wiki_page_${this.model.get('page_id')}`
        $('<a id="module_prerequisites_lookup_link" style="display: none;">')
          .attr('href', prerequisites_lookup)
          .appendTo($('.lock_explanation'))
        INST.lookupPrerequisites()
      }
    }

    // attach/re-attach the publish button
    if (!this.publishButtonView) {
      this.publishButtonView = new PublishButtonView({model: this.model})
      this.model.view = this
    }
    this.publishButtonView.$el.appendTo(this.$publishButton)
    this.publishButtonView.render()

    // attach/re-attach the sequence footer (if this is a course, but not the home page)
    if (!this.$sequenceFooter && !this.course_home && !!this.course_id) {
      if (!this.$sequenceFooter) this.$sequenceFooter = $('<div></div>').hide()
      this.$sequenceFooter.moduleSequenceFooter({
        courseID: this.course_id,
        assetType: 'Page',
        assetID: this.model.get('url'),
        location
      })
    } else if (this.$sequenceFooter != null) {
      this.$sequenceFooter.msfAnimation(false)
    }
    if (this.$sequenceFooter) return this.$sequenceFooter.appendTo(this.$el)
  }

  navigateToLinkAnchor() {
    const anchor_name = window.location.hash.replace(/^#/, '')
    if (anchor_name.length) {
      let $anchor = $(`#wiki_page_show .user_content #${anchor_name}`)
      if (!$anchor.length) {
        $anchor = $(`#wiki_page_show .user_content a[name='${anchor_name}']`)
      }
      if ($anchor.length) {
        $('html, body').scrollTo($anchor)
      }
    }
  }

  afterRender() {
    super.afterRender(...arguments)
    $('.header-bar-outer-container .header-bar-right').append($('#mark-as-done-checkbox'))
    this.navigateToLinkAnchor()
    this.reloadView = new WikiPageReloadView({
      el: this.$pageChangedAlert,
      model: this.model,
      interval: 150000,
      reloadMessage: I18n.t(
        'reload_viewing_page',
        'This page has changed since you started viewing it. *Reload*',
        {wrapper: '<a class="reload" href="#">$1</a>'}
      )
    })
    this.reloadView.on('changed', () => this.$headerBarOuterContainer.addClass('page-changed'))
    this.reloadView.on('reload', () => this.render())
    this.reloadView.pollForChanges()

    return $.publish('userContent/change')
  }

  deleteWikiPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    if (!this.model.get('deletable')) return

    const deleteDialog = new WikiPageDeleteDialog({
      model: this.model,
      wiki_pages_path: this.wiki_pages_path
    })
    return deleteDialog.open()
  }

  unsetAsFrontPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }

    return this.model.unsetFrontPage(() =>
      $('#wiki_page_show .header-bar-right .al-trigger').focus()
    )
  }

  useAsFrontPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    if (!this.model.get('published')) return

    return this.model.setFrontPage(() => $('#wiki_page_show .header-bar-right .al-trigger').focus())
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.modules_path = this.modules_path
    json.wiki_pages_path = this.wiki_pages_path
    json.wiki_page_edit_path = this.wiki_page_edit_path
    json.wiki_page_history_path = this.wiki_page_history_path
    json.course_home = this.course_home
    json.course_title = this.course_title
    json.CAN = {
      VIEW_ALL_PAGES: !!this.display_show_all_pages || !!this.WIKI_RIGHTS.manage,
      VIEW_PAGES: !!this.WIKI_RIGHTS.read,
      PUBLISH: !!this.WIKI_RIGHTS.manage && json.contextName === 'courses',
      VIEW_UNPUBLISHED: !!this.WIKI_RIGHTS.manage || !!this.WIKI_RIGHTS.view_unpublished_items,
      UPDATE_CONTENT: !!this.PAGE_RIGHTS.update || !!this.PAGE_RIGHTS.update_content,
      DELETE: !!this.PAGE_RIGHTS.delete && !this.course_home,
      READ_REVISIONS: !!this.PAGE_RIGHTS.read_revisions
    }
    json.CAN.ACCESS_GEAR_MENU = json.CAN.DELETE || json.CAN.READ_REVISIONS
    json.CAN.VIEW_TOOLBAR =
      json.CAN.VIEW_PAGES ||
      json.CAN.PUBLISH ||
      json.CAN.UPDATE_CONTENT ||
      json.CAN.ACCESS_GEAR_MENU

    if (json.lock_info) {
      json.lock_info = _.clone(json.lock_info)
    }
    if (json.lock_info != null ? json.lock_info.unlock_at : undefined) {
      json.lock_info.unlock_at =
        tz.parse(json.lock_info.unlock_at) < new Date()
          ? null
          : $.datetimeString(json.lock_info.unlock_at)
    }

    if (json.is_master_course_child_content && json.restricted_by_master_course) {
      json.cannot_delete_by_master_course = true
      json.cannot_edit_by_master_course = json.master_course_restrictions.content
    }

    json.wiki_page_menu_tools = ENV.wiki_page_menu_tools
    _.each(json.wiki_page_menu_tools, tool => {
      tool.url = `${tool.base_url}&pages[]=${this.model.get('page_id')}`
    })
    return json
  }
}
WikiPageView.initClass()
