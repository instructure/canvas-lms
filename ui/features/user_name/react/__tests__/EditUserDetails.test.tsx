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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import EditUserDetails, {type EditUserDetailsProps, type UserDetails} from '../EditUserDetails'
import {computeShortAndSortableNamesFromName} from '@canvas/user-sortable-name/react'

describe('EditUserDetails', () => {
  const timezones = [
    {
      name: 'International Date Line West',
      name_with_hour_offset: 'International Date Line West (-12:00)',
    },
    {
      name: 'American Samoa',
      name_with_hour_offset: 'American Samoa (-11:00)',
    },
  ]
  const props: EditUserDetailsProps = {
    userId: '1',
    canManageUserDetails: true,
    onClose: jest.fn(),
    onSubmit: jest.fn(),
    timezones,
    userDetails: {
      email: 'test@test.com',
      name: 'Test User',
      short_name: 'TS',
      sortable_name: 'User, Test',
      time_zone: timezones[0].name,
    },
  }
  const EDIT_USER_DETAILS_URI = `/users/${props.userId}`

  describe('when the user do not have permission to manage user details', () => {
    it('should NOT render timezone and email fields', () => {
      render(<EditUserDetails {...props} canManageUserDetails={false} />)
      const name = screen.getByLabelText('Full Name')
      const shortName = screen.getByLabelText('Display Name')
      const sortableName = screen.getByLabelText('Sortable Name')
      const timezone = screen.queryByLabelText('Time Zone')
      const email = screen.queryByLabelText('Default Email')

      expect(name).toBeInTheDocument()
      expect(shortName).toBeInTheDocument()
      expect(sortableName).toBeInTheDocument()
      expect(timezone).not.toBeInTheDocument()
      expect(email).not.toBeInTheDocument()
    })

    it('should sync short and sortable names with name if they initially the same', async () => {
      const modifiedName = `${props.userDetails.name}1`
      const computedNames = computeShortAndSortableNamesFromName({
        name: modifiedName,
        prior_name: props.userDetails.name,
        short_name: props.userDetails.short_name,
        sortable_name: props.userDetails.sortable_name,
      })
      render(<EditUserDetails {...props} canManageUserDetails={false} />)
      const name = screen.getByLabelText('Full Name')

      fireEvent.input(name, {target: {value: modifiedName}})

      const shortName = await screen.findByLabelText('Display Name')
      const sortableName = await screen.findByLabelText('Sortable Name')
      expect(shortName).toHaveValue(computedNames.short_name)
      expect(sortableName).toHaveValue(computedNames.sortable_name)
    })

    it('should show an error if the network request fails', async () => {
      fetchMock.patch(EDIT_USER_DETAILS_URI, 500, {overwriteRoutes: true})
      render(<EditUserDetails {...props} canManageUserDetails={false} />)
      const submit = screen.getByLabelText('Update Details')

      fireEvent.click(submit)

      const errorAlerts = await screen.findAllByText(
        'Updating user details failed, please try again.',
      )
      expect(errorAlerts.length).toBeTruthy()
    })

    it('should be able to submit the form if it is valid', async () => {
      const newUserDetails: Partial<UserDetails> = {
        name: 'new name',
        short_name: 'new short_name',
        sortable_name: 'new sortable_name',
      }
      fetchMock.patch(EDIT_USER_DETAILS_URI, newUserDetails, {overwriteRoutes: true})
      render(<EditUserDetails {...props} canManageUserDetails={false} />)
      const submit = screen.getByLabelText('Update Details')
      const name = screen.getByLabelText('Full Name')
      const shortName = screen.getByLabelText('Display Name')
      const sortableName = screen.getByLabelText('Sortable Name')

      fireEvent.input(name, {target: {value: newUserDetails.name}})
      fireEvent.input(shortName, {target: {value: newUserDetails.short_name}})
      fireEvent.input(sortableName, {target: {value: newUserDetails.sortable_name}})
      fireEvent.click(submit)

      await waitFor(() => {
        expect(
          fetchMock.called(EDIT_USER_DETAILS_URI, {method: 'PATCH', body: {user: newUserDetails}}),
        ).toBe(true)
        expect(props.onSubmit).toHaveBeenCalledWith(newUserDetails)
      })
    })
  })

  describe('when the user has permission to manage user details', () => {
    it('should render timezone and email fields', () => {
      render(<EditUserDetails {...props} />)
      const name = screen.getByLabelText('Full Name')
      const shortName = screen.getByLabelText('Display Name')
      const sortableName = screen.getByLabelText('Sortable Name')
      const timezone = screen.getByLabelText('Time Zone')
      const email = screen.getByLabelText('Default Email')

      expect(name).toBeInTheDocument()
      expect(shortName).toBeInTheDocument()
      expect(sortableName).toBeInTheDocument()
      expect(timezone).toBeInTheDocument()
      expect(email).toBeInTheDocument()
    })

    it('should still submit if the email field is blank', async () => {
      const newUserDetails: Partial<UserDetails> = {
        name: 'new name',
        short_name: 'new short_name',
        sortable_name: 'new sortable_name',
        time_zone: timezones[0].name,
      }
      const newProps: EditUserDetailsProps = {
        ...props,
        userDetails: {...props.userDetails, email: ''},
      }
      fetchMock.patch(EDIT_USER_DETAILS_URI, newUserDetails, {overwriteRoutes: true})
      render(<EditUserDetails {...newProps} />)

      const name = screen.getByLabelText('Full Name')
      const shortName = screen.getByLabelText('Display Name')
      const sortableName = screen.getByLabelText('Sortable Name')
      const submit = screen.getByLabelText('Update Details')

      fireEvent.input(name, {target: {value: newUserDetails.name}})
      fireEvent.input(shortName, {target: {value: newUserDetails.short_name}})
      fireEvent.input(sortableName, {target: {value: newUserDetails.sortable_name}})
      fireEvent.click(submit)

      await waitFor(() => {
        expect(
          fetchMock.called(EDIT_USER_DETAILS_URI, {method: 'PATCH', body: {user: newUserDetails}}),
        ).toBe(true)
        expect(props.onSubmit).toHaveBeenCalledWith(newUserDetails)
      })
    })

    it('should show an error message if the email field is invalid', async () => {
      const newProps: EditUserDetailsProps = {
        ...props,
        userDetails: {...props.userDetails, email: 'invalid email'},
      }
      render(<EditUserDetails {...newProps} />)
      const submit = screen.getByLabelText('Update Details')

      fireEvent.click(submit)

      const errorText = await screen.findByText('Invalid email address.')
      expect(errorText).toBeInTheDocument()
    })

    it('should be able to submit the form if it is valid', async () => {
      const newUserDetails: UserDetails = {
        name: 'new name',
        short_name: 'new short_name',
        sortable_name: 'new sortable_name',
        email: 'new@email.com',
        time_zone: timezones[1].name,
      }
      fetchMock.patch(EDIT_USER_DETAILS_URI, newUserDetails, {overwriteRoutes: true})
      render(<EditUserDetails {...props} />)
      const submit = screen.getByLabelText('Update Details')
      const name = screen.getByLabelText('Full Name')
      const shortName = screen.getByLabelText('Display Name')
      const sortableName = screen.getByLabelText('Sortable Name')
      const timezone = screen.getByLabelText('Time Zone')
      const email = screen.getByLabelText('Default Email')

      fireEvent.input(name, {target: {value: newUserDetails.name}})
      fireEvent.input(shortName, {target: {value: newUserDetails.short_name}})
      fireEvent.input(sortableName, {target: {value: newUserDetails.sortable_name}})
      fireEvent.click(timezone)
      const timezoneOption = await screen.findByText(timezones[1].name_with_hour_offset)
      fireEvent.click(timezoneOption)
      fireEvent.input(email, {target: {value: newUserDetails.email}})
      fireEvent.click(submit)

      await waitFor(() => {
        expect(
          fetchMock.called(EDIT_USER_DETAILS_URI, {method: 'PATCH', body: {user: newUserDetails}}),
        ).toBe(true)
        expect(props.onSubmit).toHaveBeenCalledWith(newUserDetails)
      })
    })
  })
})
