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
  'react-addons-test-utils'
  'react-modal'
  'jsx/external_apps/components/ManageAppListButton',
], (React, ReactDOM, TestUtils, Modal, ManageAppListButton) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  onUpdateAccessToken = ->

  createElement = ->
    React.createElement(ManageAppListButton, {
      onUpdateAccessToken: onUpdateAccessToken
    })

  renderComponent = ->
    ReactDOM.render(createElement(), wrapper)

  QUnit.module 'ExternalApps.ManageAppListButton',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'open and close modal', ->
    component = renderComponent({})
    Simulate.click(component.getDOMNode())
    ok component.state.modalIsOpen, 'modal is open'
    ok component.refs.btnClose
    ok component.refs.btnUpdateAccessToken
    Simulate.click(component.refs.btnClose.getDOMNode())
    ok !component.state.modalIsOpen, 'modal is not open'
    ok !component.refs.btnClose
    ok !component.refs.btnUpdateAccessToken

  test 'maskedAccessToken', ->
    component = renderComponent({})
    equal component.maskedAccessToken(null), null
    equal component.maskedAccessToken('token'), 'token...'
