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

  QUnit.module 'ExternalApps.AddExternalToolButton',
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

  test 'includes close button in footer if LTI2 registration', ->
    addToolButton = renderComponent({'canAddEdit': true})
    addToolButton.setState({isLti2: true})
    addToolButton.setState({modalIsOpen: true})
    ok document.querySelector('#footer-close-button')

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

      test 'renders a tool launch iframe for LTI2', ->
        addToolButton = renderComponent({'canAddEdit': true})
        addToolButton.setState({modalIsOpen: true, isLti2: true})
        ok document.querySelector('#lti2-iframe-container')

      test 'hides the configuration form once registration begins', ->
        addToolButton = renderComponent({'canAddEdit': true})
        addToolButton.setState({isLti2: false, modalIsOpen: true})
        element = document.querySelector('#lti2-iframe-container')
        style = window.getComputedStyle(element)
        equal style.getPropertyValue('display'), 'none'

      test 'submits the configuration form to the launch iframe for LTI2', ->
        addToolButton = renderComponent({'canAddEdit': true})
        addToolButton.setState({modalIsOpen: true})
        registrationUrl = 'http://www.instructure.com/register'
        iframeDouble = { submit: sinon.spy() }
        launchButton = document.querySelector('#submitExternalAppBtn')
        closestStub = sinon.stub();
        closestStub.withArgs('form').returns(iframeDouble)
        launchButton.closest = closestStub
        addToolButton.createTool('lti2', {'registrationUrl': registrationUrl}, {'currentTarget': launchButton})
        ok iframeDouble.submit.called





