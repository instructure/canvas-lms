/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

// Ideally, in the future, each form is written in such a way that they can
// be tested separately. However, because they all rely on the submit/cancel button
// rendered in ConfigurationForm.js and React Testing Library (rightly) only let's
// you test what user's see, we have to pull the testing up a level.
import {jest} from '@jest/globals'
import React from 'react'
import '@testing-library/jest-dom'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfigurationForm from '../configuration_forms/ConfigurationForm'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

const renderForm = (props: Object) => {
  return render(<ConfigurationForm {...props} />)
}

const getSubmitButton = () => {
  return screen.getByRole('button', {name: /submit/i})
}

const getMembershipServiceCheckbox = () => {
  return screen.getByLabelText(
    'Allow this tool to access the IMS Names and Role Provisioning Service'
  )
}

jest.mock('@canvas/alerts/react/FlashAlert')

const handleSubmitMock = jest.fn()

const mockedFlash = FlashAlert.showFlashAlert as jest.Mock<typeof FlashAlert.showFlashAlert>

afterEach(() => {
  jest.resetAllMocks()
})

// INTEROP-8410 - remove or rewrite to remove spies on imports
describe.skip('when configuration type is manual', () => {
  const getNameInput = () => {
    return screen.getByRole('textbox', {name: /name/i})
  }

  const getDomainInput = () => {
    return screen.getByRole('textbox', {name: /^domain$/i})
  }

  const getUrlInput = () => {
    return screen.getByRole('textbox', {name: /^launch url$/i})
  }

  const baseProps = {
    configurationType: 'manual',
    tool: {},
    handleSubmit: handleSubmitMock,
    name: undefined,
    url: undefined,
    domain: undefined,
  }

  it('renders the manual configuration form', () => {
    renderForm(baseProps)
    expect(getNameInput()).toBeInTheDocument()
    expect(getUrlInput()).toBeInTheDocument()
    expect(getDomainInput()).toBeInTheDocument()
  })

  it('tries to submit the form with the appropriate values when the submit button is clicked', async () => {
    const expected = {
      name: 'a really cool name',
      url: 'https://example.com',
      domain: 'example.com',
      consumerKey: 'key',
      sharedSecret: 'secret',
      privacyLevel: 'anonymous',
      customFields: 'foo=bar\nbaz=qux',
      description: 'a great little description',
      verifyUniqueness: 'true',
    }

    renderForm(baseProps)
    await userEvent.type(getNameInput(), expected.name)
    await userEvent.type(getUrlInput(), expected.url)
    await userEvent.type(getDomainInput(), expected.domain)
    await userEvent.type(screen.getByRole('textbox', {name: /consumer key/i}), expected.consumerKey)
    await userEvent.type(
      screen.getByRole('textbox', {name: /shared secret/i}),
      expected.sharedSecret
    )
    await userEvent.click(screen.getByRole('combobox', {name: /privacy level/i}))
    await userEvent.click(screen.getByText(/anonymous/i))

    await userEvent.type(screen.getByRole('textbox', {name: /description/i}), expected.description)
    await userEvent.type(
      screen.getByRole('textbox', {name: /custom fields/i}),
      expected.customFields
    )
    await userEvent.click(getSubmitButton())
    expect(handleSubmitMock).toHaveBeenCalledWith('manual', expected, expect.anything())
  })

  it('uses the default values passed in from props', () => {
    renderForm({
      ...baseProps,
      tool: {
        name: 'a really cool name',
        consumer_key: 'key',
        shared_secret: 'secret',
        description: 'a great little description',
      },
    })

    expect(getNameInput()).toHaveValue('a really cool name')
    expect(screen.getByLabelText(/consumer key/i)).toHaveValue('key')
    expect(screen.getByLabelText(/shared secret/i)).toHaveValue('secret')
    expect(screen.getByLabelText(/privacy/i)).toHaveValue('Anonymous')
    expect(screen.getByLabelText(/description/i)).toHaveValue('a great little description')
  })

  it('renders the allow membership service access checkbox when the appropriate flag is enabled', async () => {
    renderForm({
      ...baseProps,
      membershipServiceFeatureFlagEnabled: true,
    })

    const checkbox = getMembershipServiceCheckbox()

    expect(checkbox).toBeInTheDocument()

    await userEvent.click(checkbox)

    expect(checkbox).toBeChecked()
  })

  describe('error checking', () => {
    it('flashes an error when name is empty', async () => {
      renderForm(baseProps)
      await userEvent.click(getSubmitButton())

      // This can't use .not.toHaveBeenCalled because the submit function receives a React synthetic event,
      // and if it has been called, jest will try to print out the result of that event, which results in
      // a misleading error message about what actually happened, so toHaveBeenCalledTimes it is.
      expect(handleSubmitMock).toHaveBeenCalledTimes(0)
      expect(mockedFlash).toHaveBeenCalled()
    })

    it('renders an error next to the name input when name is empty', async () => {
      renderForm(baseProps)
      await userEvent.click(getSubmitButton())

      expect(handleSubmitMock).toHaveBeenCalledTimes(0)
      expect(screen.getByText('This field is required')).toBeInTheDocument()
    })

    describe('name has a value', () => {
      it('flashes an error when url and domain are both empty', async () => {
        renderForm(baseProps)
        await userEvent.type(getNameInput(), 'a really cool name')
        await userEvent.click(getSubmitButton())

        expect(handleSubmitMock).toHaveBeenCalledTimes(0)
        expect(mockedFlash).toHaveBeenCalled()
      })

      it('renders an error when url and domain are both empty', async () => {
        renderForm(baseProps)
        await userEvent.type(getNameInput(), 'a really cool name')
        await userEvent.click(getSubmitButton())

        expect(handleSubmitMock).toHaveBeenCalledTimes(0)
        expect(screen.getAllByText(/Either the url or domain should be set./i)).not.toHaveLength(0)
      })

      it("doesn't flash an error if just url is set and tries to submit the form", async () => {
        renderForm(baseProps)
        await userEvent.type(getNameInput(), 'a really cool name')
        await userEvent.type(getUrlInput(), 'https://example.com')
        await userEvent.click(getSubmitButton())

        expect(mockedFlash).not.toHaveBeenCalled()
        expect(handleSubmitMock).toHaveBeenCalled()
      })

      it("doesn't flash an error if just domain is set and tries to submit the form", async () => {
        renderForm(baseProps)
        await userEvent.type(getNameInput(), 'a really cool name')
        await userEvent.type(getDomainInput(), 'example.com')
        await userEvent.click(getSubmitButton())

        expect(mockedFlash).not.toHaveBeenCalled()
        expect(handleSubmitMock).toHaveBeenCalled()
      })
    })
  })
})

// INTEROP-8410 - remove or rewrite to remove spies on imports
describe.skip('when configuration type is url', () => {
  const baseProps = {
    configurationType: 'url',
    tool: {},
    handleSubmit: handleSubmitMock,
    name: undefined,
    url: undefined,
    domain: undefined,
  }

  it('renders the url configuration form', () => {
    renderForm(baseProps)
    expect(screen.getByLabelText(/config url/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/shared secret/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/consumer key/i)).toBeInTheDocument()
  })

  it('tries to submit the form with the appropriate values when the submit button is clicked', async () => {
    renderForm(baseProps)

    await userEvent.type(screen.getByLabelText(/config url/i), 'https://example.com')
    await userEvent.type(screen.getByLabelText(/consumer key/i), 'key')
    await userEvent.type(screen.getByLabelText(/shared secret/i), 'secret')
    await userEvent.type(screen.getByLabelText(/name/i), 'a really cool name')

    await userEvent.click(screen.getByText(/submit/i))

    expect(handleSubmitMock).toHaveBeenCalledWith(
      'url',
      {
        name: 'a really cool name',
        configUrl: 'https://example.com',
        consumerKey: 'key',
        sharedSecret: 'secret',
        verifyUniqueness: 'true',
      },
      expect.anything()
    )
  })

  it('renders the allow membership service access checkbox when the appropriate flag is enabled', async () => {
    renderForm({
      ...baseProps,
      membershipServiceFeatureFlagEnabled: true,
    })

    const checkbox = getMembershipServiceCheckbox()

    expect(checkbox).toBeInTheDocument()

    await userEvent.click(checkbox)

    expect(checkbox).toBeChecked()
  })

  it('uses the default values passed in from props', () => {
    renderForm({
      ...baseProps,
      tool: {
        name: 'a really cool name',
        config_url: 'https://example.com',
        consumer_key: 'key',
        shared_secret: 'secret',
      },
    })

    expect(screen.getByLabelText(/name/i)).toHaveValue('a really cool name')
    expect(screen.getByLabelText(/config url/i)).toHaveValue('https://example.com')
    expect(screen.getByLabelText(/consumer key/i)).toHaveValue('key')
    expect(screen.getByLabelText(/shared secret/i)).toHaveValue('secret')
  })

  describe('error checking', () => {
    it('flashes and renders an error when config url is empty', async () => {
      renderForm(baseProps)
      await userEvent.type(screen.getByLabelText(/name/i), 'a great name')
      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(mockedFlash).toHaveBeenCalled()
      expect(screen.getByText(/This field is required/i)).toBeInTheDocument()
    })

    it('flashes and renders error when the name is empty', async () => {
      renderForm(baseProps)
      await userEvent.type(screen.getByLabelText(/config url/i), 'https://example.com')
      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(mockedFlash).toHaveBeenCalled()
      expect(screen.getByText(/This field is required/i)).toBeInTheDocument()
    })

    it('flashes and renders multiple errors when both fields are empty', async () => {
      renderForm(baseProps)

      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(mockedFlash).toHaveBeenCalled()
      expect(screen.getAllByText(/This field is required/i)).toHaveLength(2)
    })
  })
})

// INTEROP-8410 - remove or rewrite to remove spies on imports
describe.skip('when configuration type is xml', () => {
  const baseProps = {
    configurationType: 'xml',
    tool: {},
    handleSubmit: handleSubmitMock,
    name: undefined,
    url: undefined,
    domain: undefined,
  }

  it('renders the xml configuration form', () => {
    renderForm(baseProps)
    expect(screen.getByLabelText(/xml configuration/i)).toBeInTheDocument()
  })

  it('tries to submit the form with the appropriate values when the submit button is clicked', async () => {
    renderForm(baseProps)

    await userEvent.type(screen.getByLabelText(/xml configuration/i), 'some for sure real xml')
    await userEvent.type(screen.getByLabelText(/name/i), 'a really cool name')
    await userEvent.type(screen.getByLabelText(/shared secret/i), 'secret')
    await userEvent.type(screen.getByLabelText(/consumer key/i), 'key')

    await userEvent.click(screen.getByText(/submit/i))

    expect(handleSubmitMock).toHaveBeenCalledWith(
      'xml',
      {
        name: 'a really cool name',
        xml: 'some for sure real xml',
        consumerKey: 'key',
        sharedSecret: 'secret',
        verifyUniqueness: 'true',
      },
      expect.anything()
    )
  })

  it('uses the default values passed in from props', () => {
    renderForm({
      ...baseProps,
      tool: {
        name: 'a really cool name',
        xml: 'some for sure real xml',
        consumer_key: 'key',
        shared_secret: 'secret',
      },
    })

    expect(screen.getByLabelText(/name/i)).toHaveValue('a really cool name')
    expect(screen.getByLabelText(/xml configuration/i)).toHaveValue('some for sure real xml')
    expect(screen.getByLabelText(/consumer key/i)).toHaveValue('key')
    expect(screen.getByLabelText(/shared secret/i)).toHaveValue('secret')
  })

  it('renders the allow membership service access checkbox when the appropriate flag is enabled', async () => {
    renderForm({
      ...baseProps,
      membershipServiceFeatureFlagEnabled: true,
    })

    const checkbox = getMembershipServiceCheckbox()

    expect(checkbox).toBeInTheDocument()

    await userEvent.click(checkbox)

    expect(checkbox).toBeChecked()
  })

  describe('error checking', () => {
    it('flashes and renders an error when xml configuration is empty', async () => {
      renderForm(baseProps)
      await userEvent.type(screen.getByLabelText(/name/i), 'a great name')
      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(mockedFlash).toHaveBeenCalled()
      expect(screen.getByText(/This field is required/i)).toBeInTheDocument()
    })

    it('flashes and renders error when the name is empty', async () => {
      renderForm(baseProps)
      await userEvent.type(screen.getByLabelText(/xml configuration/i), 'some for sure real xml')
      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(mockedFlash).toHaveBeenCalled()
      expect(screen.getByText(/This field is required/i)).toBeInTheDocument()
    })

    it('flashes and renders multiple errors when both fields are empty', async () => {
      renderForm(baseProps)

      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(mockedFlash).toHaveBeenCalled()
      expect(screen.getAllByText(/This field is required/i)).toHaveLength(2)
    })
  })
})

describe('when configuration type is lti2', () => {
  const baseProps = {
    configurationType: 'lti2',
    tool: {
      registration_url: '',
    },
    handleSubmit: handleSubmitMock,
    name: undefined,
    url: undefined,
    domain: undefined,
  }

  const getRegUrlInput = () => {
    return screen.getByLabelText(/registration url/i)
  }

  it('renders the lti2 configuration form', () => {
    renderForm(baseProps)
    expect(getRegUrlInput()).toBeInTheDocument()
  })

  it('tries to submit the form with the appropriate values when the submit button is clicked', async () => {
    renderForm(baseProps)
    await userEvent.type(getRegUrlInput(), 'https://example.com')

    await userEvent.click(screen.getByText(/launch registration tool/i))

    expect(handleSubmitMock).toHaveBeenCalledWith(
      'lti2',
      {
        registrationUrl: 'https://example.com',
      },
      expect.anything()
    )
  })

  describe('error checking', () => {
    it("renders an error if the registration url hasn't been filled out", async () => {
      renderForm(baseProps)

      await userEvent.click(screen.getByText(/launch registration tool/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(screen.getByLabelText(/this field is required/i)).toBeInTheDocument()
    })
  })
})
