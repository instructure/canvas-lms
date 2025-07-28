/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../jst/rosterTabs.handlebars'
import 'jqueryui/tabs'

export default class RosterTabsView extends Backbone.View {
  static initClass() {
    this.prototype.template = template

    this.prototype.tagName = 'li'
    this.prototype.className =
      'collectionViewItems ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all'
  }

  replaceHashAndFocus(tabHref) {
    const activeTab = $('#group_categories_tabs')
      .find('li')
      .filter(function () {
        return /ui-(state|tabs)-active/.test(this.className)
      })
    const activeItemHref = tabHref || activeTab.not('.static').find('a').attr('href')
    if (activeItemHref) {
      window.history.replaceState({}, document.title, activeItemHref)
    }
    if (activeTab) {
      activeTab.trigger('focus')
      activeTab.find('a').trigger('focus')
    }
  }

  isStudent() {
    // must check canManage because current_user_roles will include roles from other enrolled courses
    return ENV.current_user_roles?.includes('student') && !ENV.PERMISSIONS?.manage
  }

  attach() {
    return this.collection.on('reset', this.render, this)
  }

  fetch() {
    if (ENV.canManageCourse) {
      return this.collection.fetch()
    }
  }

  getUrlEndString(url) {
    return url.slice(url.lastIndexOf('/') + 1)
  }

  render() {
    super.render(...arguments)
    // If the referrer is any groups tab
    const referrerEnd = this.getUrlEndString(document.referrer)
    if (referrerEnd === 'groups' || referrerEnd === 'users') {
      requestAnimationFrame(() => {
        this.replaceHashAndFocus()
      })
    }
    if (this.isStudent()) {
      requestAnimationFrame(() => {
        return this.refreshTabs()
      })
    } else {
      return this.refreshTabs()
    }
  }

  refreshTabs() {
    const $tabs = $('#group_categories_tabs')
    $tabs.tabs().show()
    $tabs.tabs({
      beforeActivate: (event, ui) => {
        return ui.newTab.hasClass('static')
      },
    })

    const $groupTabs = $tabs.find('li')
    $groupTabs.find('a').off()
    const oldTab = $tabs.find('li.ui-state-active')
    const newTab = $groupTabs.not('li.ui-state-active')
    $groupTabs.on('click keyup', function (event) {
      event.stopPropagation()
      const $activeItemHref = $(this).find('a').attr('href')
      window.history.replaceState({}, document.title, $activeItemHref)
      const newTabHref = newTab.find('a').attr('href')
      const referrerEnd = newTabHref.slice(newTabHref.lastIndexOf('/') + 1)
      if (event.type === 'click' || event.key === 'Enter' || event.key === ' ') {
        window.location.href = $activeItemHref
        window.location.reload()
      } else if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
        if (newTab.length <= 1 && (referrerEnd === 'groups' || referrerEnd === 'users')) {
          oldTab.removeClass('ui-state-active ui-tabs-active')
          newTab.addClass('ui-state-active ui-tabs-active')
          newTab.find('a').trigger('focus')
          window.location.href = newTab.find('a').attr('href')
        }
      }
    })
  }

  toJSON() {
    const json = {}
    json.collection = super.toJSON(...arguments)
    json.course = ENV.course
    return json
  }
}
RosterTabsView.initClass()
