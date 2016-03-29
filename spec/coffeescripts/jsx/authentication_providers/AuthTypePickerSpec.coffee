define [
  'react'
  'jsx/authentication_providers/AuthTypePicker'
], (React, AuthTypePicker) ->

  TestUtils = React.addons.TestUtils
  Picker = null
  fixtureNode = null
  authTypes = [
    {name: 'TypeOne', value: '1'},
    {name: 'TypeTwo', value: '2'}
  ]
  authTypePicker = null

  pickFirstAuthType = ()->
    document.querySelectorAll('.react-select-box-option')[0].click()

  module 'AuthTypePicker',
   setup: ->
     Picker = React.createFactory(AuthTypePicker)
     fixtureNode = document.getElementById("fixtures")

   teardown: ->
     React.unmountComponentAtNode(fixtureNode)
     fixtureNode.innerHTML = ""

  test 'rendered structure', ->
    authTypePicker = Picker({ authTypes: authTypes })
    React.render(authTypePicker, fixtureNode)
    equal(document.querySelectorAll(".react-select-box-option").length,2)

  test "choosing an auth type fires the provided callback", ->
    changedToType = ""
    authTypePicker = Picker({
      authTypes: authTypes,
      onChange: ((authType)-> changedToType = authType )
    })
    React.render(authTypePicker, fixtureNode)
    pickFirstAuthType()
    equal(changedToType, "1")

