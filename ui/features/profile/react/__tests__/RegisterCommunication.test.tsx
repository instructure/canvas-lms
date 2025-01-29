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
import {render, screen} from '@testing-library/react'
import {userEvent} from '@testing-library/user-event'
import RegisterCommunication, {Tab} from '../RegisterCommunication'

describe('RegisterCommunication', () => {
  const onSubmit = jest.fn()

  const tabIdAndLabelMap = {
    [Tab.EMAIL]: 'Email',
    [Tab.SMS]: 'Text (SMS)',
    [Tab.SLACK]: 'Slack Email',
  }

  it.each([
    {
      availableTabs: [Tab.EMAIL],
      notAvailableTabs: [Tab.SMS, Tab.SLACK],
    },
    {
      availableTabs: [Tab.EMAIL, Tab.SMS],
      notAvailableTabs: [Tab.SLACK],
    },
    {
      availableTabs: [Tab.EMAIL, Tab.SLACK],
      notAvailableTabs: [Tab.SMS],
    },
    {
      availableTabs: [Tab.EMAIL, Tab.SMS, Tab.SLACK],
      notAvailableTabs: [],
    },
  ])('should render the available tabs: $availableTabs', ({availableTabs, notAvailableTabs}) => {
    render(<RegisterCommunication availableTabs={availableTabs} />)

    availableTabs.forEach(availableTab => {
      const tab = screen.getByText(tabIdAndLabelMap[availableTab])

      expect(tab).toBeInTheDocument()
    })
    notAvailableTabs.forEach(notAvailableTab => {
      const tab = screen.queryByText(tabIdAndLabelMap[notAvailableTab])

      expect(tab).not.toBeInTheDocument()
    })
  })

  it('should the "Email" tab be selected by default', () => {
    render(<RegisterCommunication availableTabs={[Tab.EMAIL]} />)
    const tab = screen.queryByText(tabIdAndLabelMap[Tab.EMAIL])

    expect(tab).toHaveAttribute('aria-selected', 'true')
  })

  it('should the "Text (SMS)" tab be selected if configured', () => {
    render(<RegisterCommunication availableTabs={[Tab.SMS]} />)
    const tab = screen.queryByText(tabIdAndLabelMap[Tab.SMS])

    expect(tab).toHaveAttribute('aria-selected', 'true')
  })

  describe('when the email tab is selected', () => {
    it('should show the input and the checkbox if the account is the default', () => {
      render(<RegisterCommunication availableTabs={[Tab.EMAIL]} isDefaultAccount={true} />)
      const input = screen.getByLabelText('Email')
      const checkbox = screen.getByLabelText('I want to log in to Canvas using this email address')

      expect(input).toBeInTheDocument()
      expect(checkbox).toBeInTheDocument()
    })

    it('should show only the input if the account is NOT the default', () => {
      render(<RegisterCommunication availableTabs={[Tab.EMAIL]} isDefaultAccount={false} />)
      const input = screen.getByLabelText('Email')
      const checkbox = screen.queryByLabelText(
        'I want to log in to Canvas using this email address',
      )

      expect(input).toBeInTheDocument()
      expect(checkbox).not.toBeInTheDocument()
    })

    it('should show the error message if the email is invalid', async () => {
      render(<RegisterCommunication availableTabs={[Tab.EMAIL]} />)
      const input = screen.getByLabelText('Email Address')
      const submit = screen.getByLabelText('Register Email')

      await userEvent.type(input, 'invalid email')
      await userEvent.click(submit)

      expect(screen.getByText('Email is invalid!')).toBeInTheDocument()
    })

    it('should show the error if the email is empty', async () => {
      render(<RegisterCommunication availableTabs={[Tab.EMAIL]} />)
      const submit = screen.getByLabelText('Register Email')

      await userEvent.click(submit)

      expect(screen.getByText('Email is required')).toBeInTheDocument()
    })

    it('should send the correct payload if the email is valid and checkbox is checked', async () => {
      render(
        <RegisterCommunication
          availableTabs={[Tab.EMAIL]}
          isDefaultAccount={true}
          onSubmit={onSubmit}
        />,
      )
      const inputValue = 'test@test.com'
      const input = screen.getByLabelText('Email Address')
      const checkbox = screen.getByLabelText('I want to log in to Canvas using this email address')
      const submit = screen.getByLabelText('Register Email')

      await userEvent.type(input, inputValue)
      await userEvent.click(checkbox)
      await userEvent.click(submit)

      expect(onSubmit).toHaveBeenCalledWith(inputValue, Tab.EMAIL, true)
    })

    it('should send the correct payload if the email is valid and checkbox is unchecked', async () => {
      render(
        <RegisterCommunication
          availableTabs={[Tab.EMAIL]}
          isDefaultAccount={true}
          onSubmit={onSubmit}
        />,
      )
      const inputValue = 'test@test.com'
      const input = screen.getByLabelText('Email Address')
      const submit = screen.getByLabelText('Register Email')

      await userEvent.type(input, inputValue)
      await userEvent.click(submit)

      expect(onSubmit).toHaveBeenCalledWith(inputValue, Tab.EMAIL, false)
    })
  })

  describe('when the sms tab is selected', () => {
    it('should only allow to enter numbers in the mobile number input', async () => {
      render(<RegisterCommunication availableTabs={[Tab.SMS]} initiallySelectedTab={Tab.SMS} />)
      const input = screen.getByLabelText('Mobile Number')

      await userEvent.type(input, '5555-foo-1%$#')

      expect(input).toHaveValue('55551')
    })

    it('should show the error message if the mobile number is invalid (too long)', async () => {
      render(<RegisterCommunication availableTabs={[Tab.SMS]} initiallySelectedTab={Tab.SMS} />)
      const input = screen.getByLabelText('Mobile Number')
      const submit = screen.getByLabelText('Register SMS')

      await userEvent.type(input, '55555555555555555555555')
      await userEvent.click(submit)

      expect(screen.getByText('Should be 10-digit number')).toBeInTheDocument()
    })

    it('should show the error if the email is empty', async () => {
      render(<RegisterCommunication availableTabs={[Tab.SMS]} initiallySelectedTab={Tab.SMS} />)
      const submit = screen.getByLabelText('Register SMS')

      await userEvent.click(submit)

      expect(screen.getByText('Cell Number is required')).toBeInTheDocument()
    })

    it('should send the correct payload if the mobile number is valid', async () => {
      render(
        <RegisterCommunication
          availableTabs={[Tab.SMS]}
          initiallySelectedTab={Tab.SMS}
          onSubmit={onSubmit}
        />,
      )
      const inputValue = '5555555555'
      const input = screen.getByLabelText('Mobile Number')
      const submit = screen.getByLabelText('Register SMS')

      await userEvent.type(input, inputValue)
      await userEvent.click(submit)

      expect(onSubmit).toHaveBeenCalledWith(inputValue, Tab.SMS, undefined)
    })
  })

  describe('when the slack tab is selected', () => {
    it('should show the error message if the slack email is invalid', async () => {
      render(<RegisterCommunication availableTabs={[Tab.SLACK]} initiallySelectedTab={Tab.SLACK} />)
      const input = screen.getByTestId('slack-email')
      const submit = screen.getByLabelText('Register Slack Email')

      await userEvent.type(input, 'invalid email')
      await userEvent.click(submit)

      expect(screen.getByText('Email is invalid!')).toBeInTheDocument()
    })

    it('should show the error if the slack email is empty', async () => {
      render(<RegisterCommunication availableTabs={[Tab.SLACK]} initiallySelectedTab={Tab.SLACK} />)
      const submit = screen.getByLabelText('Register Slack Email')

      await userEvent.click(submit)

      expect(screen.getByText('Email is required')).toBeInTheDocument()
    })

    it('should send the correct payload if the slack email is valid', async () => {
      render(
        <RegisterCommunication
          availableTabs={[Tab.SLACK]}
          initiallySelectedTab={Tab.SLACK}
          onSubmit={onSubmit}
        />,
      )
      const inputValue = 'test@test.com'
      const input = screen.getByTestId('slack-email')
      const submit = screen.getByLabelText('Register Slack Email')

      await userEvent.type(input, inputValue)
      await userEvent.click(submit)

      expect(onSubmit).toHaveBeenCalledWith(inputValue, Tab.SLACK, undefined)
    })
  })
})
