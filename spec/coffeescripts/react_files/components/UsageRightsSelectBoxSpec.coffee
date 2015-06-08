define [
  'jquery'
  'underscore'
  'react'
  'compiled/react_files/components/UsageRightsSelectBox'
  ], ($, _, React, UsageRightsSelectBox ) ->

    UsageRightsSelectBox = React.createFactory(UsageRightsSelectBox)
    TestUtils = React.addons.TestUtils

    module "UsageRightsSelectBox",
    test "shows alert message if nothing is chosen and component is setup for a message", ->
      props = {
        showMessage: true
      }

      uRSB = TestUtils.renderIntoDocument(UsageRightsSelectBox(props))
      ok uRSB.refs.showMessageAlert != undefined, "message is being shown"
      React.unmountComponentAtNode(uRSB.getDOMNode().parentNode)

    test "fetches license options when component mounts", ->
      server = sinon.fakeServer.create()
      props = {
        showMessage: false
      }

      uRSB = TestUtils.renderIntoDocument(UsageRightsSelectBox(props))

      server.respond 'GET', "", [200, {
        'Content-Type': 'application/json'
      }, JSON.stringify({dataHere: "catfish"})]

      equal uRSB.state.licenseOptions.dataHere, "catfish", 'sets data just fine'

      server.restore()
      React.unmountComponentAtNode(uRSB.getDOMNode().parentNode)

    test "inserts copyright into textbox when passed in", ->
      copyright = "all dogs go to taco bell"
      props = {
        copyright: copyright
      }

      uRSB = TestUtils.renderIntoDocument(UsageRightsSelectBox(props))
      equal uRSB.refs.copyright.getDOMNode().value, copyright
      React.unmountComponentAtNode(uRSB.getDOMNode().parentNode)

    test "shows creative commons options when set up", ->
      server = sinon.fakeServer.create()
      cc_value = "helloooo_nurse"
      props = {
        copyright: 'loony'
        use_justification: 'creative_commons'
        cc_value: cc_value
      }

      uRSB = TestUtils.renderIntoDocument(UsageRightsSelectBox(props))
      server.respond 'GET', "", [200, {
        'Content-Type': 'application/json'
      }, JSON.stringify([{id: ['cc'], name: 'CreativeCommonsOption' }])]

      equal uRSB.refs.creativeCommons.getDOMNode().value, "cc", "shows creative commons option"

      server.restore()
      React.unmountComponentAtNode(uRSB.getDOMNode().parentNode)
