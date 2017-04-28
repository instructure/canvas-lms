#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'jquery'
  'underscore'
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/files/UsageRightsSelectBox'
  ], ($, _, React, ReactDOM, TestUtils, UsageRightsSelectBox ) ->

    QUnit.module "UsageRightsSelectBox",
      setup: ->
      teardown: ->
        $("div.error_box").remove()

    test "shows alert message if nothing is chosen and component is setup for a message", ->
      props = {
        showMessage: true
      }

      uRSB = TestUtils.renderIntoDocument(React.createElement(UsageRightsSelectBox, props))
      ok uRSB.refs.showMessageAlert != undefined, "message is being shown"
      ReactDOM.unmountComponentAtNode(uRSB.getDOMNode().parentNode)

    test "fetches license options when component mounts", ->
      server = sinon.fakeServer.create()
      props = {
        showMessage: false
      }

      uRSB = TestUtils.renderIntoDocument(React.createElement(UsageRightsSelectBox, props))

      server.respond 'GET', "", [200, {
        'Content-Type': 'application/json'
      }, JSON.stringify([{id: 'cc_some_option', name: 'CreativeCommonsOption' }])]

      equal uRSB.state.licenseOptions[0].id, "cc_some_option", 'sets data just fine'

      server.restore()
      ReactDOM.unmountComponentAtNode(uRSB.getDOMNode().parentNode)

    test "inserts copyright into textbox when passed in", ->
      copyright = "all dogs go to taco bell"
      props = {
        copyright: copyright
      }

      uRSB = TestUtils.renderIntoDocument(React.createElement(UsageRightsSelectBox, props))
      equal uRSB.refs.copyright.getDOMNode().value, copyright
      ReactDOM.unmountComponentAtNode(uRSB.getDOMNode().parentNode)

    test "shows creative commons options when set up", ->
      server = sinon.fakeServer.create()
      cc_value = "helloooo_nurse"
      props = {
        copyright: 'loony'
        use_justification: 'creative_commons'
        cc_value: cc_value
      }

      uRSB = TestUtils.renderIntoDocument(React.createElement(UsageRightsSelectBox, props))
      server.respond 'GET', "", [200, {
        'Content-Type': 'application/json'
      }, JSON.stringify([{id: 'cc_some_option', name: 'CreativeCommonsOption' }])]

      equal uRSB.refs.creativeCommons.getDOMNode().value, "cc_some_option", "shows creative commons option"

      server.restore()
      ReactDOM.unmountComponentAtNode(uRSB.getDOMNode().parentNode)
