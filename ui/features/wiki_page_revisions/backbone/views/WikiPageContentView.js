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
import {clone} from 'lodash'
import Backbone from '@canvas/backbone'
import template from '../../jst/WikiPageContent.handlebars'
import {publish} from 'jquery-tinypubsub'

export default class WikiPageContentView extends Backbone.View {
  static initClass() {
    this.prototype.tagName = 'article'
    this.prototype.className = 'show-content user_content'
    this.prototype.template = template

    this.optionProperty('modules_path')
    this.optionProperty('wiki_pages_path')
    this.optionProperty('wiki_page_edit_path')
    this.optionProperty('wiki_page_history_path')
    this.optionProperty('WIKI_RIGHTS')
    this.optionProperty('PAGE_RIGHTS')
    this.optionProperty('course_id')
    this.optionProperty('course_home')
    this.optionProperty('course_title')
  }

  initialize() {
    super.initialize(...arguments)
    if (!this.WIKI_RIGHTS) this.WIKI_RIGHTS = {}
    if (!this.PAGE_RIGHTS) this.PAGE_RIGHTS = {}
    return this.setModel(this.model)
  }

  afterRender() {
    super.afterRender(...arguments)
    publish('userContent/change')
    return this.trigger('render')
  }

  setModel(model) {
    if (this.model != null) {
      this.model.off(null, null, this)
    }

    this.model = model
    if (this.model != null) {
      this.model.on('change:title', () => this.render(), this)
    }
    if (this.model != null) {
      this.model.on('change:body', () => this.render(), this)
    }
    return this.render()
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
      VIEW_ALL_PAGES: !!this.display_show_all_pages,
      VIEW_PAGES: !!this.WIKI_RIGHTS.read,
      PUBLISH: !!this.WIKI_RIGHTS.publish_page,
      UPDATE_CONTENT: !!this.PAGE_RIGHTS.update || !!this.PAGE_RIGHTS.update_content,
      DELETE: !!this.PAGE_RIGHTS.delete && !this.course_home,
      READ_REVISIONS: !!this.PAGE_RIGHTS.read_revisions,
    }
    json.CAN.ACCESS_GEAR_MENU = json.CAN.DELETE || json.CAN.READ_REVISIONS
    json.CAN.VIEW_TOOLBAR =
      json.CAN.VIEW_PAGES ||
      json.CAN.PUBLISH ||
      json.CAN.UPDATE_CONTENT ||
      json.CAN.ACCESS_GEAR_MENU

    if (json.lock_info) {
      json.lock_info = clone(json.lock_info)
    }
    if (json.lock_info != null ? json.lock_info.unlock_at : undefined) {
      json.lock_info.unlock_at =
        Date.parse(json.lock_info.unlock_at) < Date.now()
          ? null
          : $.datetimeString(json.lock_info.unlock_at)
    }

    return json
  }
}
WikiPageContentView.initClass()
