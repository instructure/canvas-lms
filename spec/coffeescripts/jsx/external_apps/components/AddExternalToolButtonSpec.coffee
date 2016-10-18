define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'react-modal'
  'jsx/external_apps/components/AddExternalToolButton'
], (React, ReactDOM, TestUtils, Modal, AddExternalToolButton) ->

  Simulate = TestUtils.Simulate
  wrapper = null

  createElement = (data = {}) ->
    React.createElement(AddExternalToolButton, data)

  renderComponent = (data = {}) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = ->
    component = renderComponent()
    {
      component: component
      addToolButton: component.refs.addTool?.getDOMNode()
      modal: component.refs.modal?.getDOMNode()
      lti2Permissions: component.refs.lti2Permissions?.getDOMNode()
      lti2Iframe: component.refs.lti2Iframe?.getDOMNode()
      configurationForm: component.refs.configurationForm?.getDOMNode()
    }

  module 'ExternalApps.AddExternalToolButton',
    setup: ->
      wrapper = document.getElementById('fixtures')
      wrapper.innerHTML = ''
      Modal.setAppElement(wrapper)

    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper
      wrapper.innerHTML = ''

  test 'render', ->
    nodes = getDOMNodes()
    ok nodes.component.isMounted()
    ok TestUtils.isCompositeComponentWithType(nodes.component, AddExternalToolButton)

  test 'bad config url error message', ->
    addToolButton = renderComponent()
    xhr = {}
    addToolButton.setState({configurationType: 'url'})
    xhr.responseText = JSON.stringify({
     "errors":{
        "url":[
           {
              "attribute":"url",
              "type":"Either the url or domain should be set.",
              "message":"Either the url or domain should be set."
           }
        ],
        "domain":[
           {
              "attribute":"domain",
              "type":"Either the url or domain should be set.",
              "message":"Either the url or domain should be set."
           }
        ],
        "config_url":[
           {
              "attribute":"config_url",
              "type":"Invalid Config URL",
              "message":"Invalid Config URL"
           }
        ]
      }
    })
    equal addToolButton._errorHandler(xhr), 'Invalid Config URL'

    test 'bad config xml error message', ->
      addToolButton = renderComponent()
      addToolButton.setState({configurationType: 'xml'})
      xhr = {}
      xhr.responseText = JSON.stringify({
       "errors":{
          "url":[
             {
                "attribute":"url",
                "type":"Either the url or domain should be set.",
                "message":"Either the url or domain should be set."
             }
          ],
          "config_xml":[
             {
                "attribute":"config_url",
                "type": "Invalid XML Configuration",
                "message": "Invalid XML Configuration"
             }
          ]
        }
      })
      equal addToolButton._errorHandler(xhr), 'Invalid XML Configuration'

      test 'firs error message', ->
        addToolButton = renderComponent()
        xhr = {}
        xhr.responseText = JSON.stringify({
         "errors":{
            "url":[
               {
                  "attribute":"url",
                  "type":"Either the url or domain should be set.",
                  "message":"Either the url or domain should be set."
               }
            ],
            "domain":[
               {
                  "attribute":"domain",
                  "type":"Second error message",
                  "message":"Second error message"
               }
            ]
          }
        })
        equal addToolButton._errorHandler(xhr), 'Either the url or domain should be set.'

      test 'default error message', ->
        addToolButton = renderComponent()
        xhr = {}
        xhr.responseText = JSON.stringify({
          "errors":[{"message":"An error occurred.","error_code":"internal_server_error"}],
          "error_report_id":8
        })
        equal addToolButton._errorHandler(xhr), 'We were unable to add the app.'

      test 'gives access error message when permission not granted', ->
        component = renderComponent({'canAddEdit': false})
        accessDeniedMessage = 'This action has been disabled by your admin.'
        form = JSON.stringify(component.renderForm())
        ok form.indexOf(accessDeniedMessage) >= 0

      test 'gives no access error message when permission is granted', ->
        component = renderComponent({'canAddEdit': true})
        accessDeniedMessage = 'This action has been disabled by your admin.'
        form = JSON.stringify(component.renderForm())
        notOk form.indexOf(accessDeniedMessage) >= 0

