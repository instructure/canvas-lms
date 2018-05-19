/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import React from 'react'
import {mount} from 'enzyme'
import AddExternalToolButton from 'jsx/external_apps/components/AddExternalToolButton'

QUnit.module('AddExternalToolButton', suiteHooks => {
  let props
  let server
  let wrapper

  suiteHooks.beforeEach(() => {
    server = sinon.fakeServer.create()
    sinon.spy($, 'flashError')
    props = {}
  })

  suiteHooks.afterEach(() => {
    wrapper.setState({modalIsOpen: false}) // close the modal, if open
    $.flashError.restore()
    server.restore()
  })

  function mountComponent() {
    wrapper = mount(<AddExternalToolButton {...props} />)
  }

  test('renders the duplicate confirmation form when "duplicateTool" is true', function() {
    props.canAddEdit = true
    mountComponent()
    wrapper.setState({duplicateTool: true, modalIsOpen: true})
    strictEqual(document.querySelectorAll('#duplicate-confirmation-form').length, 1)
  })

  QUnit.module('#handleLti2ToolInstalled()', () => {
    test('displays a flash message from the tool when there is an error', () => {
      mountComponent()
      const toolData = {
        message: 'Something bad happened',
        status: 'failure'
      }
      wrapper.instance().handleLti2ToolInstalled(toolData)
      strictEqual($.flashError.callCount, 1)
    })

    test('displays the message included with the error', () => {
      mountComponent()
      const toolData = {
        message: 'Something bad happened',
        status: 'failure'
      }
      wrapper.instance().handleLti2ToolInstalled(toolData)
      const [message] = $.flashError.lastCall.args
      equal(message, 'Something bad happened')
    })

    test('displays a default flash message when the error does not include a message', () => {
      mountComponent()
      const toolData = {
        status: 'failure'
      }
      wrapper.instance().handleLti2ToolInstalled(toolData)
      const [message] = $.flashError.lastCall.args
      equal(message, 'There was an unknown error registering the tool')
    })
  })

  QUnit.module('when not using LTI2 registration', () => {
    test('hides the configuration form once registration begins', function() {
      props.canAddEdit = true
      mountComponent()
      wrapper.setState({isLti2: false, modalIsOpen: true})
      const element = document.querySelector('#lti2-iframe-container')
      const style = window.getComputedStyle(element)
      equal(style.getPropertyValue('display'), 'none')
    })

    test('submits the configuration form to the launch iframe for LTI2', function() {
      props.canAddEdit = true
      mountComponent()
      wrapper.setState({isLti2: false, modalIsOpen: true})
      const registrationUrl = 'http://www.instructure.com/register'
      const iframeDouble = {submit: sinon.spy()}
      const launchButton = document.querySelector('#submitExternalAppBtn')
      launchButton.closest = sinon.stub()
      launchButton.closest.withArgs('form').returns(iframeDouble)
      wrapper.instance().createTool('lti2', {registrationUrl}, {currentTarget: launchButton})
      strictEqual(iframeDouble.submit.callCount, 1)
    })
  })

  QUnit.module('when using LTI2 registration', () => {
    test('includes close button in footer', () => {
      props.canAddEdit = true
      mountComponent()
      wrapper.setState({isLti2: true, modalIsOpen: true})
      strictEqual(document.querySelectorAll('#footer-close-button').length, 1)
    })

    test('renders a tool launch iframe for LTI2', () => {
      props.canAddEdit = true
      mountComponent()
      wrapper.setState({isLti2: true, modalIsOpen: true})
      strictEqual(document.querySelectorAll('#lti2-iframe-container').length, 1)
    })
  })

  QUnit.module('#_errorHandler()', () => {
    test('returns a message for invalid configuration url', function() {
      mountComponent()
      wrapper.setState({configurationType: 'url'})
      const xhr = {
        responseText: JSON.stringify({
          errors: {
            url: [
              {
                attribute: 'url',
                type: 'Either the url or domain should be set.',
                message: 'Either the url or domain should be set.'
              }
            ],
            domain: [
              {
                attribute: 'domain',
                type: 'Either the url or domain should be set.',
                message: 'Either the url or domain should be set.'
              }
            ],
            config_url: [
              {
                attribute: 'config_url',
                type: 'Invalid Config URL',
                message: 'Invalid Config URL'
              }
            ]
          }
        })
      }
      equal(wrapper.instance()._errorHandler(xhr), 'Invalid Config URL')
    })

    test('returns a message for invalid XML configuration', function() {
      mountComponent()
      wrapper.setState({configurationType: 'xml'})
      const xhr = {
        responseText: JSON.stringify({
          errors: {
            url: [
              {
                attribute: 'url',
                type: 'Either the url or domain should be set.',
                message: 'Either the url or domain should be set.'
              }
            ],
            config_xml: [
              {
                attribute: 'config_url',
                type: 'Invalid XML Configuration',
                message: 'Invalid XML Configuration'
              }
            ]
          }
        })
      }
      equal(wrapper.instance()._errorHandler(xhr), 'Invalid XML Configuration')
    })

    test('returns a message for url or domain not being set', function() {
      mountComponent()
      const xhr = {
        responseText: JSON.stringify({
          errors: {
            url: [
              {
                attribute: 'url',
                type: 'Either the url or domain should be set.',
                message: 'Either the url or domain should be set.'
              }
            ],
            domain: [
              {
                attribute: 'domain',
                type: 'Second error message',
                message: 'Second error message'
              }
            ]
          }
        })
      }
      equal(wrapper.instance()._errorHandler(xhr), 'Either the url or domain should be set.')
    })

    test('returns a default error message when handling an unspecified error', function() {
      mountComponent()
      const xhr = {
        responseText: JSON.stringify({
          errors: [{message: 'An error occurred.', error_code: 'internal_server_error'}],
          error_report_id: 8
        })
      }
      equal(wrapper.instance()._errorHandler(xhr), 'We were unable to add the app.')
    })

    test('renders the duplicate confirmation form when duplicate tool response is received', function() {
      mountComponent()
      wrapper.setState({modalIsOpen: true, duplicateTool: true, configurationType: 'xml'})
      const xhr = {
        responseText: JSON.stringify({
          errors: {
            tool_currently_installed: [
              {
                type: 'The tool is already installed in this context.',
                message: 'The tool is already installed in this context.'
              }
            ]
          }
        })
      }
      wrapper.instance()._errorHandler(xhr)
      strictEqual(document.querySelectorAll('#duplicate-confirmation-form').length, 1)
    })
  })
})
