#
# Copyright (C) 2016 - present Instructure, Inc.
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

define [
  'react'
  'react-dom'
  'jsx/external_apps/components/EditExternalToolButton'
], (React, ReactDOM, EditExternalToolButton) ->

  wrapper = document.getElementById('fixtures')
  prevEnvironment = ENV

  createElement = (data = {}) ->
    React.createElement(EditExternalToolButton, data)

  renderComponent = (data = {}) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.EditExternalToolButton',
    setup: ->
      ENV.APP_CENTER = {'enabled': true}

    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)
      ENV = prevEnvironment

  test 'allows editing of tools', ->
    tool = {'name': 'test tool'}
    component = renderComponent({'tool': tool, 'canAddEdit': true})
    disabledMessage = 'This action has been disabled by your admin.'
    form = JSON.stringify(component.form())
    notOk form.indexOf(disabledMessage) >= 0


