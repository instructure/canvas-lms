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

import React from 'react'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import 'jquery-scroll-to-visible'
import * as tz from '@canvas/datetime'
import {clone, each} from 'lodash'
import Backbone from '@canvas/backbone'
import template from '../../jst/WikiPage.handlebars'
import StickyHeaderMixin from '@canvas/wiki/backbone/views/StickyHeaderMixin'
import WikiPageDeleteDialog from '@canvas/wiki/backbone/views/WikiPageDeleteDialog'
import WikiPageReloadView from '@canvas/wiki/backbone/views/WikiPageReloadView'
import PublishButtonView from '@canvas/publish-button-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from '@instructure/html-escape'
import {publish} from 'jquery-tinypubsub'
import '@canvas/modules/jquery/prerequisites_lookup'
import '../../jquery/content_locks'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import {renderFrontPagePill} from '@canvas/wiki/react/renderFrontPagePill'

const I18n = useI18nScope('pages')

export default class WikiPageView extends Backbone.View {
  static initClass() {
    this.mixin(StickyHeaderMixin)

    this.prototype.template = template

    this.prototype.els = {
      '.publish-button': '$publishButton',
      '.header-bar-outer-container': '$headerBarOuterContainer',
      '.page-changed-alert': '$pageChangedAlert',
      '.al-trigger': '$gearMenu',
    }

    this.prototype.events = {
      'click .delete_page': 'deleteWikiPage',
      'click .use-as-front-page-menu-item': 'useAsFrontPage',
      'click .unset-as-front-page-menu-item': 'unsetAsFrontPage',
      'click .direct-share-send-to-menu-item': 'openSendTo',
      'click .direct-share-copy-to-menu-item': 'openCopyTo',
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
          .attr('x-canvaslms-trusted-url', prerequisites_lookup)
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

    // Attach the immersive reader button if enabled
    const immersive_reader_mount_point = document.getElementById('immersive_reader_mount_point')
    const immersive_reader_mobile_mount_point = document.getElementById(
      'immersive_reader_mobile_mount_point'
    )
    if (immersive_reader_mount_point || immersive_reader_mobile_mount_point) {
      import(
        /* webpackChunkName: "[request]" */
        '@canvas/immersive-reader/ImmersiveReader'
      )
        .then(({initializeReaderButton}) => {
          const content = () => document.querySelector('.show-content').innerHTML
          const title = document.querySelector('.page-title').textContent

          if (immersive_reader_mount_point) {
            initializeReaderButton(immersive_reader_mount_point, {content, title})
          }

          if (immersive_reader_mobile_mount_point) {
            initializeReaderButton(immersive_reader_mobile_mount_point, {
              content,
              title,
            })
          }
        })
        .catch(e => {
          console.log('Error loading immersive readers.', e) // eslint-disable-line no-console
        })
    }

    // Fixes issue when using anchors IDs scroll. Sometimes the browsers can't find the element
    // due it is not loaded yet.
    if (window.location?.hash !== '') {
      window.location.href = window.location.hash
    }

    // Adds class if a LTI iframe is embed in content
    const ltisEmbedded = $('.show-content iframe.lti-embed')
    if (ltisEmbedded.length > 0) {
      $('.show-content').addClass('lti-content')
      ltisEmbedded.each(function () {
        $(this).closest('p').addClass('lti-embed-container')
      })
    }

    // attach/re-attach the sequence footer (if this is a course, but not the home page)
    if (!this.$sequenceFooter && !this.course_home && !!this.course_id) {
      if (!this.$sequenceFooter) this.$sequenceFooter = $('<div></div>').hide()
      this.$sequenceFooter.moduleSequenceFooter({
        courseID: this.course_id,
        assetType: 'Page',
        assetID: this.model.get('url'),
        onFetchSuccess: () => {
          $('.module-sequence-footer-content').append($('#mark-as-done-container'))
          $('#mark-as-done-container').css({float: 'right', 'margin-right': '4px'})
        },
      })
    } else if (this.$sequenceFooter != null) {
      this.$sequenceFooter.msfAnimation(false)
    }
    if (this.$sequenceFooter) return this.$sequenceFooter.appendTo($('#module_navigation_target'))
  }

  navigateToLinkAnchor() {
    const anchor_name = window.location.hash.replace(/^#/, '')
    if (anchor_name.length) {
      let $anchor = $(`#wiki_page_show .user_content #${anchor_name}`)
      if (!$anchor.length) {
        $anchor = $(`#wiki_page_show .user_content a[name='${anchor_name}']`)
      }
      if ($anchor.length) {
        $('html, body').scrollToVisible($anchor)
      }
    }
  }

  afterRender() {
    super.afterRender(...arguments)
    this.navigateToLinkAnchor()
    this.reloadView = new WikiPageReloadView({
      el: this.$pageChangedAlert,
      model: this.model,
      interval: 150000,
      reloadMessage: I18n.t(
        'reload_viewing_page',
        'This page has changed since you started viewing it. *Reload*',
        {wrapper: '<a class="reload" href="#">$1</a>'}
      ),
    })
    this.reloadView.on('changed', () => this.$headerBarOuterContainer.addClass('page-changed'))
    this.reloadView.on('reload', () => this.render())
    this.reloadView.pollForChanges()

    renderFrontPagePill(this.$el[0], {
      margin: 'small',
      children: this.toJSON().frontPageText,
    })

    return publish('userContent/change')
  }

  deleteWikiPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    if (!this.model.get('deletable')) return

    const deleteDialog = new WikiPageDeleteDialog({
      model: this.model,
      wiki_pages_path: this.wiki_pages_path,
    })
    return deleteDialog.open()
  }

  unsetAsFrontPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }

    return this.model.unsetFrontPage(() =>
      $('#wiki_page_show .page-toolbar .buttons .al-trigger').focus()
    )
  }

  useAsFrontPage(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    if (!this.model.get('published')) return

    return this.model.setFrontPage(() =>
      $('#wiki_page_show .page-toolbar .buttons .al-trigger').focus()
    )
  }

  openSendTo(ev, open = true) {
    if (ev) ev.preventDefault()
    ReactDOM.render(
      <DirectShareUserModal
        open={open}
        sourceCourseId={this.course_id}
        contentShare={{content_type: 'page', content_id: this.model.id}}
        onDismiss={() => {
          this.openSendTo(null, false)
          this.$gearMenu.focus()
        }}
      />,
      document.getElementById('direct-share-mount-point')
    )
  }

  openCopyTo(ev, open = true) {
    if (ev) ev.preventDefault()
    ReactDOM.render(
      <DirectShareCourseTray
        open={open}
        sourceCourseId={this.course_id}
        contentSelection={{pages: [this.model.id]}}
        onDismiss={() => {
          this.openCopyTo(null, false)
          this.$gearMenu.focus()
        }}
      />,
      document.getElementById('direct-share-mount-point')
    )
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.page_id = this.model.get('page_id')
    json.modules_path = this.modules_path
    json.wiki_pages_path = this.wiki_pages_path
    json.wiki_page_edit_path = this.wiki_page_edit_path
    json.wiki_page_history_path = this.wiki_page_history_path
    json.course_home = this.course_home
    json.course_title = this.course_title
    json.CAN = {
      VIEW_ALL_PAGES: !!this.display_show_all_pages || !!this.WIKI_RIGHTS.manage,
      VIEW_PAGES: !!this.WIKI_RIGHTS.read,
      PUBLISH: !!this.WIKI_RIGHTS.publish_page,
      VIEW_UNPUBLISHED: !!this.WIKI_RIGHTS.manage || !!this.WIKI_RIGHTS.view_unpublished_items,
      UPDATE_CONTENT: !!this.PAGE_RIGHTS.update || !!this.PAGE_RIGHTS.update_content,
      DELETE: !!this.PAGE_RIGHTS.delete && !this.course_home,
      READ_REVISIONS: !!this.PAGE_RIGHTS.read_revisions,
    }
    json.CAN.DIRECT_SHARE = !!ENV.DIRECT_SHARE_ENABLED
    json.CAN.ACCESS_GEAR_MENU = json.CAN.DELETE || json.CAN.READ_REVISIONS || json.CAN.DIRECT_SHARE
    json.CAN.VIEW_TOOLBAR =
      json.course_home ||
      json.CAN.VIEW_ALL_PAGES ||
      json.CAN.PUBLISH ||
      json.CAN.UPDATE_CONTENT ||
      json.CAN.ACCESS_GEAR_MENU
    json.recent_announcements_enabled = !!ENV.SHOW_ANNOUNCEMENTS
    json.explicit_latex_typesetting = !!ENV.FEATURES?.explicit_latex_typesetting

    if (json.lock_info) {
      json.lock_info = clone(json.lock_info)
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
    each(json.wiki_page_menu_tools, tool => {
      tool.url = `${tool.base_url}&pages[]=${this.model.get('page_id')}`
    })
    json.frontPageText = ENV.K5_SUBJECT_COURSE ? I18n.t('Subject Home') : I18n.t('Front Page')
    return json
  }
}
WikiPageView.initClass()
