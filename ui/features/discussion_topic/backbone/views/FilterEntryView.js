/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {extend} from '@canvas/backbone/utils'
import {View} from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../jst/results_entry.handlebars'

const I18n = useI18nScope('discussions')

extend(FilterEntryView, View)

function FilterEntryView() {
  this.updateReadState = this.updateReadState.bind(this)
  return FilterEntryView.__super__.constructor.apply(this, arguments)
}

FilterEntryView.prototype.els = {
  '.discussion_entry:first': '$entryContent',
  '.discussion-read-state-btn:first': '$readStateToggle',
}

FilterEntryView.prototype.events = {
  click: 'click',
  'click .discussion-read-state-btn': 'toggleRead',
}

FilterEntryView.prototype.tagName = 'li'

FilterEntryView.prototype.className = 'entry'

FilterEntryView.prototype.template = template

FilterEntryView.prototype.initialize = function () {
  FilterEntryView.__super__.initialize.apply(this, arguments)
  return this.model.on('change:read_state', this.updateReadState)
}

FilterEntryView.prototype.toJSON = function () {
  const json = this.model.attributes
  json.edited_at = $.datetimeString(json.updated_at)
  if (json.editor) {
    json.editor_name = json.editor.display_name
    json.editor_href = json.editor.html_url
  } else {
    json.editor_name = I18n.t('unknown', 'Unknown')
    json.editor_href = '#'
  }
  return json
}

FilterEntryView.prototype.click = function () {
  return this.trigger('click', this)
}

FilterEntryView.prototype.afterRender = function () {
  FilterEntryView.__super__.afterRender.apply(this, arguments)
  return this.updateReadState()
}

FilterEntryView.prototype.toggleRead = function (e) {
  e.stopPropagation()
  e.preventDefault()
  if (this.model.get('read_state') === 'read') {
    return this.model.markAsUnread()
  } else {
    return this.model.markAsRead()
  }
}

FilterEntryView.prototype.updateReadState = function () {
  this.updateTooltip()
  this.$entryContent.toggleClass('unread', this.model.get('read_state') === 'unread')
  return this.$entryContent.toggleClass('read', this.model.get('read_state') === 'read')
}

FilterEntryView.prototype.updateTooltip = function () {
  const tooltip =
    this.model.get('read_state') === 'unread'
      ? I18n.t('mark_as_read', 'Mark as Read')
      : I18n.t('mark_as_unread', 'Mark as Unread')
  return this.$readStateToggle.attr('title', tooltip)
}

export default FilterEntryView
