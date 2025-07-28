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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
// Ideally, in the future, each form is written in such a way that they can
// be tested separately. However, because they all rely on the submit/cancel button
// rendered in ConfigurationForm.js and React Testing Library (rightly) only let's
// you test what user's see, we have to pull the testing up a level.
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfigurationForm from '../configuration_forms/ConfigurationForm'

jest.mock('@canvas/alerts/react/FlashAlert')

const renderForm = (props: object) => {
  return render(<ConfigurationForm {...props} />)
}

const getSubmitButton = () => {
  return screen.getByRole('button', {name: /submit/i})
}

const getMembershipServiceCheckbox = () => {
  return screen.getByLabelText(
    'Allow this tool to access the IMS Names and Role Provisioning Service',
  )
}

const handleSubmitMock = jest.fn()

afterEach(() => {
  jest.clearAllMocks()
})

// Pasting is much faster than typing, and we don't need
// to test specific event handling.
const userPaste = async (input: HTMLElement, text: string) => {
  await userEvent.click(input)
  await userEvent.paste(text)
}

describe('when configuration type is manual', () => {
  const getNameInput = () => {
    return screen.getByRole('textbox', {name: /name/i})
  }

  const getDomainInput = () => {
    return screen.getByRole('textbox', {name: /^domain$/i})
  }

  const getUrlInput = () => {
    return screen.getByRole('textbox', {name: /^launch url/i})
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
    await userPaste(getNameInput(), expected.name)
    await userPaste(getUrlInput(), expected.url)
    await userPaste(getDomainInput(), expected.domain)

    await userPaste(screen.getByRole('textbox', {name: /consumer key/i}), expected.consumerKey)
    await userPaste(screen.getByRole('textbox', {name: /shared secret/i}), expected.sharedSecret)
    await userEvent.click(screen.getByRole('combobox', {name: /privacy level/i}))
    await userEvent.click(screen.getByText(/anonymous/i))

    await userPaste(screen.getByRole('textbox', {name: /description/i}), expected.description)
    await userPaste(screen.getByRole('textbox', {name: /custom fields/i}), expected.customFields)
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
    it('renders an error next to the name input when name is empty', async () => {
      renderForm(baseProps)
      await userEvent.click(getSubmitButton())

      expect(handleSubmitMock).toHaveBeenCalledTimes(0)
      expect(screen.getByText('This field is required')).toBeInTheDocument()
    })

    describe('name has a value', () => {
      it('renders an error when url and domain are both empty', async () => {
        renderForm(baseProps)
        await userPaste(getNameInput(), 'a really cool name')
        await userEvent.click(getSubmitButton())

        expect(handleSubmitMock).toHaveBeenCalledTimes(0)
        expect(
          screen.getAllByText(/One or both of Launch URL and Domain should be entered./i),
        ).not.toHaveLength(0)
      })
    })
  })
})

describe('when configuration type is url', () => {
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

    await userPaste(screen.getByLabelText(/shared secret/i), 'secret')
    await userPaste(screen.getByLabelText(/consumer key/i), 'key')
    await userPaste(screen.getByLabelText(/config url/i), 'https://example.com')
    await userPaste(screen.getByLabelText(/name/i), 'a really cool name')

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
      expect.anything(),
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
      await userPaste(screen.getByLabelText(/name/i), 'a great name')
      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(
        screen.getByText(/please enter a valid url \(e\.g\. https:\/\/example\.com\)/i),
      ).toBeInTheDocument()
    })

    it('renders error when the name is empty', async () => {
      renderForm(baseProps)
      await userPaste(screen.getByLabelText(/config url/i), 'https://example.com')
      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(screen.getByText(/This field is required/i)).toBeInTheDocument()
    })

    it('renders multiple errors when both fields are empty', async () => {
      renderForm(baseProps)

      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(screen.getAllByText(/This field is required/i)).toHaveLength(1)
    })
  })
})

describe('when configuration type is xml', () => {
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

    await userPaste(screen.getByLabelText(/xml configuration/i), 'some for sure real xml')
    await userPaste(screen.getByLabelText(/shared secret/i), 'secret')
    await userPaste(screen.getByLabelText(/consumer key/i), 'key')
    await userPaste(screen.getByLabelText(/name/i), 'a really cool name')

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
      expect.anything(),
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
    it('renders an error when xml configuration is empty', async () => {
      renderForm(baseProps)
      await userPaste(screen.getByLabelText(/name/i), 'a great name')
      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(screen.getByText(/This field is required/i)).toBeInTheDocument()
    })

    it('renders error when the name is empty', async () => {
      renderForm(baseProps)
      await userPaste(screen.getByLabelText(/xml configuration/i), 'some for sure real xml')
      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(screen.getByText(/This field is required/i)).toBeInTheDocument()
    })

    it('renders multiple errors when both fields are empty', async () => {
      renderForm(baseProps)

      await userEvent.click(screen.getByText(/submit/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
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
    await userPaste(getRegUrlInput(), 'https://example.com')

    await userEvent.click(screen.getByText(/launch registration tool/i))

    expect(handleSubmitMock).toHaveBeenCalledWith(
      'lti2',
      {
        registrationUrl: 'https://example.com',
      },
      expect.anything(),
    )
  })

  describe('error checking', () => {
    it("renders an error if the registration url hasn't been filled out", async () => {
      renderForm(baseProps)

      await userEvent.click(screen.getByText(/launch registration tool/i))

      expect(handleSubmitMock).not.toHaveBeenCalled()
      expect(
        screen.getByText(/please enter a valid url \(e\.g\. https:\/\/example\.com\)/i),
      ).toBeInTheDocument()
    })
  })
})
