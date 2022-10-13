//
// Copyright (C) 2014 - present Instructure, Inc.
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

  attach() {
    return this.collection.on('reset', this.render, this)
  }

  fetch() {
    if (ENV.canManageCourse) {
      return this.collection.fetch()
    }
  }

  render() {
    super.render(...arguments)
    return this.refreshTabs()
  }

  refreshTabs() {
    const $tabs = $('#group_categories_tabs')
    $tabs.tabs().show()
    $tabs.tabs({
      beforeActivate(event, ui) {
        return ui.newTab.hasClass('static')
      },
    })

    const $groupTabs = $tabs.find('li').not('.static')
    $groupTabs.find('a').unbind()
    return $groupTabs.on('keydown', function (event) {
      event.stopPropagation()
      if (event.keyCode === 13 || event.keyCode === 32) {
        return (window.location.href = $(this).find('a').attr('href'))
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
