#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/ExternalToolLaunch.handlebars'
import $ from 'jquery'

export default class ExternalToolLaunchView extends Backbone.View
  template: template

  events:
    "click #externalToolLaunch": "launchExternalTool"

  els:
    '.file_name': '$fileName'

  @optionProperty 'contentReturnView'

  initialize: (options) ->
    super(options)
    @contentReturnView.on 'ready', @setUrl

  launchExternalTool: (event) ->
    event.preventDefault()
    @contentReturnView.render()

  setUrl: (data) =>
    item = data.contentItems[0]
    @$fileName.text(item.text)
    @model.set('settings', {file_url: item.url})
