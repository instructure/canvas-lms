/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfigurationForm from '../ConfigurationForm'
import $ from 'jquery'

describe('ConfigurationForm', () => {
  const renderConfigurationForm = (props = {}) => {
    const defaultProps = {
      configurationType: 'manual',
      handleSubmit: jest.fn(),
      tool: {},
      showConfigurationSelector: true,
    }
    return render(<ConfigurationForm {...defaultProps} {...props} />)
  }

  beforeEach(() => {
    // Mock jQuery's ajax method to prevent actual network requests
    const mockJQueryResponse = {
      done: jest.fn(function (callback) {
        callback?.()
        return this
      }),
      fail: jest.fn(function (_callback) {
        return this
      }),
      always: jest.fn(function (callback) {
        callback?.()
        return this
      }),
      abort: jest.fn(),
      state: () => 'resolved',
      status: 200,
      statusText: 'OK',
      responseJSON: {},
    }

    $.ajax = jest.fn().mockReturnValue(mockJQueryResponse)

    // Mock jQuery's animate method since we use it for scrolling
    $.fn.animate = jest.fn()
  })

  afterEach(() => {
    document.body.innerHTML = ''
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })

  describe('form type rendering', () => {
    it('renders manual form with new tool', () => {
      renderConfigurationForm({
        configurationType: 'manual',
      })
      expect(screen.getByText('Manual Entry')).toBeInTheDocument()
      expect(screen.getByLabelText('Configuration Type')).toBeInTheDocument()
    })

    it('renders url form with new tool', () => {
      renderConfigurationForm({
        configurationType: 'url',
      })
      expect(screen.getByText('By URL')).toBeInTheDocument()
      expect(screen.getByLabelText('Configuration Type')).toBeInTheDocument()
    })

    it('renders xml form with new tool', () => {
      renderConfigurationForm({
        configurationType: 'xml',
      })
      expect(screen.getByText('Paste XML')).toBeInTheDocument()
      expect(screen.getByLabelText('Configuration Type')).toBeInTheDocument()
    })

    it('renders lti2 form with new tool', () => {
      renderConfigurationForm({
        configurationType: 'lti2',
      })
      expect(screen.getByText('By LTI 2 Registration URL')).toBeInTheDocument()
      expect(screen.getByLabelText('Configuration Type')).toBeInTheDocument()
    })

    it('renders LTI 1.3 form when byClientId is chosen', () => {
      renderConfigurationForm({
        configurationType: 'byClientId',
      })
      expect(screen.getByText('By Client ID')).toBeInTheDocument()
      expect(screen.getByLabelText('Configuration Type')).toBeInTheDocument()
    })

    it('renders manual form with existing tool and no selector', () => {
      renderConfigurationForm({
        configurationType: 'manual',
        showConfigurationSelector: false,
      })
      expect(screen.getByLabelText('Name *')).toBeInTheDocument()
      expect(screen.queryByLabelText('Configuration Type')).not.toBeInTheDocument()
    })
  })

  // cf. INTEROP-9131
  describe.skip('form submission', () => {
    it('saves manual form with trimmed props', async () => {
      const handleSubmit = jest.fn()
      const tool = {
        name: '  My App',
        consumerKey: '  key',
        sharedSecret: '  secret',
        url: '  http://example.com',
        domain: '  ',
        description: 'My super awesome example app',
        customFields: 'a=1\nb=2\nc=3',
      }

      const {getByLabelText, getByRole} = renderConfigurationForm({
        configurationType: 'manual',
        handleSubmit,
        tool,
      })

      // Fill in form fields
      const nameInput = getByLabelText('Name *')
      await userEvent.clear(nameInput)
      await userEvent.type(nameInput, tool.name)

      const consumerKeyInput = getByLabelText('Consumer Key')
      await userEvent.clear(consumerKeyInput)
      await userEvent.type(consumerKeyInput, tool.consumerKey)

      const sharedSecretInput = getByLabelText('Shared Secret')
      await userEvent.clear(sharedSecretInput)
      await userEvent.type(sharedSecretInput, tool.sharedSecret)

      const urlInput = getByLabelText('Launch URL *')
      await userEvent.clear(urlInput)
      await userEvent.type(urlInput, tool.url)

      const domainInput = getByLabelText('Domain')
      await userEvent.clear(domainInput)
      await userEvent.type(domainInput, tool.domain)

      const descriptionInput = getByLabelText('Description')
      await userEvent.clear(descriptionInput)
      await userEvent.type(descriptionInput, tool.description)

      const customFieldsInput = getByLabelText('Custom Fields')
      await userEvent.clear(customFieldsInput)
      await userEvent.type(customFieldsInput, tool.customFields)

      const submitButton = getByRole('button', {name: /submit/i})
      await userEvent.click(submitButton)

      await waitFor(() => {
        expect(handleSubmit).toHaveBeenCalledWith(
          'manual',
          {
            name: 'My App',
            consumerKey: 'key',
            sharedSecret: 'secret',
            url: 'http://example.com',
            domain: '',
            description: 'My super awesome example app',
            customFields: 'a=1\nb=2\nc=3',
            privacyLevel: 'anonymous',
            verifyUniqueness: 'true',
          },
          expect.any(Object),
        )
      })
    })

    it('saves url form with trimmed props', async () => {
      const handleSubmit = jest.fn()
      const tool = {
        name: '  My App',
        consumerKey: '  key',
        sharedSecret: '  secret',
        configUrl: '  http://example.com',
      }

      const {getByLabelText, getByRole} = renderConfigurationForm({
        configurationType: 'url',
        handleSubmit,
        tool,
      })

      // Fill in form fields
      const nameInput = getByLabelText('Name *')
      await userEvent.clear(nameInput)
      await userEvent.type(nameInput, tool.name)

      const consumerKeyInput = getByLabelText('Consumer Key')
      await userEvent.clear(consumerKeyInput)
      await userEvent.type(consumerKeyInput, tool.consumerKey)

      const sharedSecretInput = getByLabelText('Shared Secret')
      await userEvent.clear(sharedSecretInput)
      await userEvent.type(sharedSecretInput, tool.sharedSecret)

      const configUrlInput = getByLabelText('Config URL *')
      await userEvent.clear(configUrlInput)
      await userEvent.type(configUrlInput, tool.configUrl)

      const submitButton = getByRole('button', {name: /submit/i})
      await userEvent.click(submitButton)

      await waitFor(() => {
        expect(handleSubmit).toHaveBeenCalledWith(
          'url',
          {
            name: 'My App',
            consumerKey: 'key',
            sharedSecret: 'secret',
            configUrl: 'http://example.com',
            verifyUniqueness: 'true',
          },
          expect.any(Object),
        )
      })
    })

    it('saves xml form with trimmed props', async () => {
      const handleSubmit = jest.fn()
      const tool = {
        name: '  My App',
        consumerKey: '  key',
        sharedSecret: '  secret',
        xml: '  some xml',
      }

      const {getByLabelText, getByRole} = renderConfigurationForm({
        configurationType: 'xml',
        handleSubmit,
        tool,
      })

      // Fill in form fields
      const nameInput = getByLabelText('Name *')
      await userEvent.clear(nameInput)
      await userEvent.type(nameInput, tool.name)

      const consumerKeyInput = getByLabelText('Consumer Key')
      await userEvent.clear(consumerKeyInput)
      await userEvent.type(consumerKeyInput, tool.consumerKey)

      const sharedSecretInput = getByLabelText('Shared Secret')
      await userEvent.clear(sharedSecretInput)
      await userEvent.type(sharedSecretInput, tool.sharedSecret)

      const xmlInput = getByLabelText('XML Configuration')
      await userEvent.clear(xmlInput)
      await userEvent.type(xmlInput, tool.xml)

      const submitButton = getByRole('button', {name: /submit/i})
      await userEvent.click(submitButton)

      await waitFor(() => {
        expect(handleSubmit).toHaveBeenCalledWith(
          'xml',
          {
            name: 'My App',
            consumerKey: 'key',
            sharedSecret: 'secret',
            xml: 'some xml',
            verifyUniqueness: 'true',
          },
          expect.any(Object),
        )
      })
    })

    it('saves lti2 form with trimmed props', async () => {
      const handleSubmit = jest.fn()
      const tool = {
        registrationUrl: '  https://lti-tool-provider-example..com/register',
      }

      const {getByLabelText, getByRole} = renderConfigurationForm({
        configurationType: 'lti2',
        handleSubmit,
        tool,
      })

      // Fill in form fields
      const registrationUrlInput = getByLabelText('Registration URL *')
      await userEvent.clear(registrationUrlInput)
      await userEvent.type(registrationUrlInput, tool.registrationUrl)

      const submitButton = getByRole('button', {name: /launch registration tool/i})
      await userEvent.click(submitButton)

      await waitFor(() => {
        expect(handleSubmit).toHaveBeenCalledWith(
          'lti2',
          {
            registrationUrl: 'https://lti-tool-provider-example..com/register',
          },
          expect.any(Object),
        )
      })
    })
  })

  describe('LTI2 specific behavior', () => {
    it('returns null for iframeTarget if configuration type is not lti2', () => {
      const {container} = renderConfigurationForm({
        configurationType: 'manual',
      })
      const form = container.querySelector('form')
      expect(form.getAttribute('target')).toBeNull()
    })

    it('returns lti2_registration_frame for iframeTarget if configuration type is lti2', () => {
      const {container} = renderConfigurationForm({
        configurationType: 'lti2',
      })
      const form = container.querySelector('form')
      expect(form.getAttribute('target')).toBe('lti2_registration_frame')
    })

    it('sets the form method to post', () => {
      const {container} = renderConfigurationForm({
        configurationType: 'lti2',
      })
      const form = container.querySelector('form')
      expect(form.getAttribute('method')).toBe('post')
    })
  })
})
