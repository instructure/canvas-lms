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
import {setupTabKeyboardNavigation} from '@canvas/util/tabKeyboardNavigation'
import 'jqueryui/tabs'

export default class RosterTabsView extends Backbone.View {
  static initClass() {
    this.prototype.template = template

    this.prototype.tagName = 'li'
    this.prototype.className =
      'collectionViewItems ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all'
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
    if (this.isStudent()) {
      requestAnimationFrame(() => {
        this.refreshTabs()
      })
    } else {
      this.refreshTabs()
    }
  }

  refreshTabs() {
    const $tabs = $('#group_categories_tabs')
    $tabs.tabs().show()

    // Check if we came from internal navigation (groups or users page)
    const referrerEnd = this.getUrlEndString(document.referrer)
    const isInternalNavigation =
      document.referrer && new URL(document.referrer).origin === window.location.origin
    const needsVoiceOverDelay =
      (referrerEnd === 'groups' || referrerEnd === 'users') && isInternalNavigation

    // Set up W3C ARIA-compliant keyboard navigation for tabs
    // Arrow keys navigate AND load pages automatically
    setupTabKeyboardNavigation($tabs, {
      autoActivate: true,
      handleHashNavigation: true,
      useVoiceOverDelay: needsVoiceOverDelay,
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
