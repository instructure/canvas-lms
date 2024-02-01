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
import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/ExternalToolLaunch.handlebars'

extend(ExternalToolLaunchView, Backbone.View)

function ExternalToolLaunchView() {
  this.setUrl = this.setUrl.bind(this)
  return ExternalToolLaunchView.__super__.constructor.apply(this, arguments)
}

ExternalToolLaunchView.prototype.template = template

ExternalToolLaunchView.prototype.events = {
  'click #externalToolLaunch': 'launchExternalTool',
}

ExternalToolLaunchView.prototype.els = {
  '.file_name': '$fileName',
}

ExternalToolLaunchView.optionProperty('contentReturnView')

ExternalToolLaunchView.prototype.initialize = function (options) {
  ExternalToolLaunchView.__super__.initialize.call(this, options)
  return this.contentReturnView.on('ready', this.setUrl)
}

ExternalToolLaunchView.prototype.launchExternalTool = function (event) {
  event.preventDefault()
  return this.contentReturnView.render()
}

// data is ExternalContentReady event data or other object with contentItems
// (grep codebase for "trigger..ready")
ExternalToolLaunchView.prototype.setUrl = function (data) {
  const item = data.contentItems[0]
  this.$fileName.text(item.text)
  return this.model.set('settings', {
    file_url: item.url,
  })
}

export default ExternalToolLaunchView
