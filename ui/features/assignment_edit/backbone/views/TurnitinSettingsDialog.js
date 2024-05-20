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

import {extend} from '@canvas/backbone/utils'
import turnitinSettingsDialog from '../../jst/TurnitinSettingsDialog.handlebars'
import {extend as lodashExtend} from 'lodash'
import vericiteSettingsDialog from '../../jst/VeriCiteSettingsDialog.handlebars'
import {View} from '@canvas/backbone'
import htmlEscape from '@instructure/html-escape'
import '@canvas/util/jquery/fixDialogButtons'

const EXCLUDE_SMALL_MATCHES_OPTIONS = '.js-exclude-small-matches-options'

const EXCLUDE_SMALL_MATCHES = '#exclude_small_matches'

const EXCLUDE_SMALL_MATCHES_TYPE = '[name="exclude_small_matches_type"]'

extend(TurnitinSettingsDialog, View)

TurnitinSettingsDialog.prototype.tagName = 'div'

function TurnitinSettingsDialog(model, type) {
  this.handleSubmit = this.handleSubmit.bind(this)
  this.getFormValues = this.getFormValues.bind(this)
  this.renderEl = this.renderEl.bind(this)
  this.toJSON = this.toJSON.bind(this)
  this.toggleExcludeOptions = this.toggleExcludeOptions.bind(this)
  TurnitinSettingsDialog.__super__.constructor.call(this, {
    model,
  })
  this.type = type
}

TurnitinSettingsDialog.prototype.events = (function () {
  const events = {}
  events.submit = 'handleSubmit'
  events['change ' + EXCLUDE_SMALL_MATCHES] = 'toggleExcludeOptions'
  return events
})()

TurnitinSettingsDialog.prototype.els = (function () {
  const els = {}
  els['' + EXCLUDE_SMALL_MATCHES_OPTIONS] = '$excludeSmallMatchesOptions'
  els['' + EXCLUDE_SMALL_MATCHES] = '$excludeSmallMatches'
  els['' + EXCLUDE_SMALL_MATCHES_TYPE] = '$excludeSmallMatchesType'
  return els
})()

TurnitinSettingsDialog.prototype.toggleExcludeOptions = function () {
  if (this.$excludeSmallMatches.prop('checked')) {
    return this.$excludeSmallMatchesOptions.show()
  } else {
    return this.$excludeSmallMatchesOptions.hide()
  }
}

TurnitinSettingsDialog.prototype.toJSON = function () {
  const json = TurnitinSettingsDialog.__super__.toJSON.apply(this, arguments)
  return lodashExtend(json, {
    wordsInput:
      '<input class="span1" id="exclude_small_matches_words_value" name="words" value="' +
      htmlEscape(json.words) +
      '" type="text"/>',
    percentInput:
      '<input class="span1" id="exclude_small_matches_percent_value" name="percent" value="' +
      htmlEscape(json.percent) +
      '" type="text"/>',
  })
}

TurnitinSettingsDialog.prototype.renderEl = function () {
  let html
  if (this.type === 'vericite') {
    html = vericiteSettingsDialog(this.toJSON())
  } else {
    html = turnitinSettingsDialog(this.toJSON())
  }
  this.$el.html(html)
  return this.$el
    .dialog({
      width: 'auto',
      modal: true,
      zIndex: 1000,
    })
    .fixDialogButtons()
}

TurnitinSettingsDialog.prototype.getFormValues = function () {
  const values = this.$el.find('form').toJSON()
  if (this.$excludeSmallMatches.prop('checked')) {
    if (values.exclude_small_matches_type === 'words') {
      values.exclude_small_matches_value = values.words
    } else {
      values.exclude_small_matches_value = values.percent
    }
  } else {
    values.exclude_small_matches_type = null
    values.exclude_small_matches_value = null
  }
  return values
}

TurnitinSettingsDialog.prototype.handleSubmit = function (ev) {
  ev.preventDefault()
  ev.stopPropagation()
  this.$el.dialog('close')
  return this.trigger('settings:change', this.getFormValues())
}

export default TurnitinSettingsDialog
