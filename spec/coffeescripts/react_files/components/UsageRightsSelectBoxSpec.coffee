define [
  'jquery'
  'underscore'
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/files/UsageRightsSelectBox'
  ], ($, _, React, ReactDOM, TestUtils, UsageRightsSelectBox ) ->

    module "UsageRightsSelectBox",
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
