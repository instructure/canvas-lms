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

define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/Configurations'
], (React, ReactDOM, TestUtils, Configurations) ->

  wrapper = document.getElementById('fixtures')

  createElement = (data = {}) ->
    React.createElement(Configurations, data)

  renderComponent = (data = {}) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.Configurations',
    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'renders', ->
    component = renderComponent({
      'env': {
        'APP_CENTER':{'enabled': true}
      }
    })
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Configurations)

  test 'canAddEdit', ->
    component = renderComponent({
        'env': {
          'PERMISSIONS': {
            'create_tool_manually': false
            },
          'APP_CENTER':{'enabled': true}
          }
      })
    notOk component.canAddEdit()

    test 'canAddEdit', ->
      component = renderComponent({
          'env': {
            'PERMISSIONS': {
              'create_tool_manually': true
              },
            'APP_CENTER':{'enabled': true}
            }
        })
      ok component.canAddEdit()

