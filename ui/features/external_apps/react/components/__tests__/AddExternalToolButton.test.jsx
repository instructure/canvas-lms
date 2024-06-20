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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AddExternalToolButton from '../AddExternalToolButton'

describe('AddExternalToolButton', () => {
  beforeEach(() => {
    jest.spyOn($, 'flashErrorSafe')
    userEvent.setup()
  })

  afterEach(() => {
    $.flashErrorSafe.mockRestore()
  })

  test('renders the duplicate confirmation form when "duplicateTool" is true', () => {
    render(<AddExternalToolButton duplicateTool={true} modalIsOpen={true} />)
    expect(screen.getByText(/This tool has already been installed/)).toBeInTheDocument()
  })

  describe('handleLti2ToolInstalled()', () => {
    test('displays a flash message from the tool when there is an error', () => {
      const ref = React.createRef()
      render(<AddExternalToolButton ref={ref} />)
      const toolData = {
        message: {html: 'Something bad happened'},
        status: 'failure',
      }
      ref.current.handleLti2ToolInstalled(toolData)
      expect($.flashErrorSafe).toHaveBeenCalledTimes(1)
    })

    test('displays the message included with the error', () => {
      const ref = React.createRef()
      render(<AddExternalToolButton ref={ref} />)
      const toolData = {
        message: 'Something bad happened',
        status: 'failure',
      }
      ref.current.handleLti2ToolInstalled(toolData)
      const [message] = $.flashErrorSafe.mock.lastCall
      expect(message).toBe('Something bad happened')
    })

    test('displays a default flash message when the error does not include a message', () => {
      const ref = React.createRef()
      render(<AddExternalToolButton ref={ref} />)
      const toolData = {
        status: 'failure',
      }
      ref.current.handleLti2ToolInstalled(toolData)
      const [message] = $.flashErrorSafe.mock.lastCall
      expect(message).toBe('There was an unknown error registering the tool')
    })
  })

  describe('when not using LTI2 registration', () => {
    test('hides the configuration form once registration begins', () => {
      render(<AddExternalToolButton isLti2={false} modalIsOpen={true} />)
      const element = screen.getByTestId('lti2-iframe-container')
      expect(element).toHaveStyle({display: 'none'})
    })

    test('submits the configuration form to the launch iframe for LTI2', async () => {
      const ref = React.createRef()
      render(
        <AddExternalToolButton
          isLti2={false}
          modalIsOpen={true}
          ref={ref}
          configurationType="lti2"
        />
      )
      await userEvent.selectOptions(
        screen.getByRole('combobox', {name: /Configuration Type/i}),
        'By LTI 2 Registration URL'
      )
      const registrationUrl = 'http://www.instructure.com/register'
      const iframeDouble = {submit: jest.fn()}
      const launchButton = screen.getByText(/Launch Registration Tool/i)
      // This is a disgrace and should be fixed but would require a huge rewrite of the components,
      // so here we are.
      launchButton.closest = jest.fn()
      launchButton.closest.mockReturnValue(iframeDouble)
      ref.current.createTool('lti2', {registrationUrl}, {currentTarget: launchButton})
      expect(iframeDouble.submit).toHaveBeenCalledTimes(1)
    })
  })

  describe('when using LTI2 registration', () => {
    test('includes close button in footer', () => {
      render(<AddExternalToolButton isLti2={true} modalIsOpen={true} />)
      expect(screen.getByTestId('lti2-close-button')).toBeInTheDocument()
    })

    test('renders a tool launch iframe for LTI2', () => {
      render(<AddExternalToolButton isLti2={true} modalIsOpen={true} />)
      expect(screen.getByTestId('lti2-iframe-container')).toBeInTheDocument()
    })
  })

  describe('_errorHandler()', () => {
    test('returns a message for invalid configuration url', () => {
      const ref = React.createRef()
      render(<AddExternalToolButton configurationType="url" ref={ref} />)
      const xhr = {
        responseText: JSON.stringify({
          errors: {
            url: [
              {
                attribute: 'url',
                type: 'Either the url or domain should be set.',
                message: 'Either the url or domain should be set.',
              },
            ],
            domain: [
              {
                attribute: 'domain',
                type: 'Either the url or domain should be set.',
                message: 'Either the url or domain should be set.',
              },
            ],
            config_url: [
              {
                attribute: 'config_url',
                type: 'Invalid Config URL',
                message: 'Invalid Config URL',
              },
            ],
          },
        }),
      }
      expect(ref.current._errorHandler(xhr)).toBe('Invalid Config URL')
    })

    test('returns a message for invalid XML configuration', () => {
      const ref = React.createRef()
      render(<AddExternalToolButton configurationType="xml" ref={ref} />)
      const xhr = {
        responseText: JSON.stringify({
          errors: {
            url: [
              {
                attribute: 'url',
                type: 'Either the url or domain should be set.',
                message: 'Either the url or domain should be set.',
              },
            ],
            config_xml: [
              {
                attribute: 'config_url',
                type: 'Invalid XML Configuration',
                message: 'Invalid XML Configuration',
              },
            ],
          },
        }),
      }
      expect(ref.current._errorHandler(xhr)).toBe('Invalid XML Configuration')
    })

    test('returns a message for url or domain not being set', () => {
      const ref = React.createRef()
      render(<AddExternalToolButton ref={ref} />)
      const xhr = {
        responseText: JSON.stringify({
          errors: {
            url: [
              {
                attribute: 'url',
                type: 'Either the url or domain should be set.',
                message: 'Either the url or domain should be set.',
              },
            ],
            domain: [
              {
                attribute: 'domain',
                type: 'Second error message',
                message: 'Second error message',
              },
            ],
          },
        }),
      }
      expect(ref.current._errorHandler(xhr)).toBe('Either the url or domain should be set.')
    })

    test('returns a default error message when handling an unspecified error', () => {
      const ref = React.createRef()
      render(<AddExternalToolButton ref={ref} />)
      const xhr = {
        responseText: JSON.stringify({
          errors: [{message: 'An error occurred.', error_code: 'internal_server_error'}],
          error_report_id: 8,
        }),
      }
      expect(ref.current._errorHandler(xhr)).toBe('We were unable to add the app.')
    })

    test('renders the duplicate confirmation form when duplicate tool response is received', () => {
      const ref = React.createRef()
      render(
        <AddExternalToolButton
          modalIsOpen={true}
          duplicateTool={true}
          configurationType="xml"
          ref={ref}
        />
      )
      const xhr = {
        responseText: JSON.stringify({
          errors: {
            tool_currently_installed: [
              {
                type: 'The tool is already installed in this context.',
                message: 'The tool is already installed in this context.',
              },
            ],
          },
        }),
      }
      ref.current._errorHandler(xhr)
      expect(screen.getByText(/This tool has already been installed/)).toBeInTheDocument()
    })
  })
})
