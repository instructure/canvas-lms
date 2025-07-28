/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import DefaultAccountQuotas from '../DefaultAccountQuotas'
import {AccountWithQuotas} from '../common'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'

describe('DefaultAccountQuotas', () => {
  const accountWithQuotas: AccountWithQuotas = {
    id: '1',
    root_account: true,
    site_admin: true,
    default_group_storage_quota_mb: 400,
    default_storage_quota_mb: 200,
    default_user_storage_quota_mb: 100,
  }
  const ACCOUNT_API_URI = `/api/v1/accounts/${accountWithQuotas.id}`

  describe('when the account is a root account', () => {
    afterEach(() => {
      fetchMock.restore()
    })

    it('should show the user quota input', () => {
      render(<DefaultAccountQuotas accountWithQuotas={accountWithQuotas} />)
      const userQuota = screen.getByLabelText(/user quota \*/i)

      expect(userQuota).toBeInTheDocument()
    })

    it('should show error messages when fields are empty', async () => {
      render(<DefaultAccountQuotas accountWithQuotas={accountWithQuotas} />)
      const courseQuota = screen.getByLabelText(/course quota \*/i)
      const userQuota = screen.getByLabelText(/user quota \*/i)
      const groupQuota = screen.getByLabelText(/group quota \*/i)
      const submit = screen.getByLabelText('Update')

      await userEvent.clear(courseQuota)
      await userEvent.clear(userQuota)
      await userEvent.clear(groupQuota)
      await userEvent.click(submit)

      const courseQuotaErrorMessage = screen.getByText('Course Quota is required.')
      const userQuotaErrorMessage = screen.getByText('User Quota is required.')
      const groupQuotaErrorMessage = screen.getByText('Group Quota is required.')
      expect(courseQuotaErrorMessage).toBeInTheDocument()
      expect(userQuotaErrorMessage).toBeInTheDocument()
      expect(groupQuotaErrorMessage).toBeInTheDocument()
    })

    it('should show error messages when fields are not integers', async () => {
      render(<DefaultAccountQuotas accountWithQuotas={accountWithQuotas} />)
      const courseQuota = screen.getByLabelText(/course quota \*/i)
      const userQuota = screen.getByLabelText(/user quota \*/i)
      const groupQuota = screen.getByLabelText(/group quota \*/i)
      const submit = screen.getByLabelText('Update')
      const invalidQuota = 'invalid'

      await userEvent.type(courseQuota, invalidQuota)
      await userEvent.type(userQuota, invalidQuota)
      await userEvent.type(groupQuota, invalidQuota)
      await userEvent.click(submit)

      const courseQuotaErrorMessage = screen.getByText('Course Quota must be an integer.')
      const userQuotaErrorMessage = screen.getByText('User Quota must be an integer.')
      const groupQuotaErrorMessage = screen.getByText('Group Quota must be an integer.')
      expect(courseQuotaErrorMessage).toBeInTheDocument()
      expect(userQuotaErrorMessage).toBeInTheDocument()
      expect(groupQuotaErrorMessage).toBeInTheDocument()
    })

    it('should show a warning message when a quota exceeds 100000', async () => {
      render(<DefaultAccountQuotas accountWithQuotas={accountWithQuotas} />)
      const courseQuota = screen.getByLabelText(/course quota \*/i)
      const userQuota = screen.getByLabelText(/user quota \*/i)
      const groupQuota = screen.getByLabelText(/group quota \*/i)
      const submit = screen.getByLabelText('Update')
      const largeQuota = '100001'

      await userEvent.type(courseQuota, largeQuota)
      await userEvent.type(userQuota, largeQuota)
      await userEvent.type(groupQuota, largeQuota)
      await userEvent.click(submit)

      const warningMessage = screen.getAllByText('This storage quota may exceed typical usage.')
      expect(warningMessage).toHaveLength(3)
    })

    it('should send the correct request when the form is submitted', async () => {
      fetchMock.put(ACCOUNT_API_URI, 200, {overwriteRoutes: true})
      render(<DefaultAccountQuotas accountWithQuotas={accountWithQuotas} />)
      const courseQuota = screen.getByLabelText(/course quota \*/i)
      const submit = screen.getByLabelText('Update')
      const courseQuotaValue = '1000'

      await userEvent.clear(courseQuota)
      await userEvent.type(courseQuota, courseQuotaValue)
      await userEvent.click(submit)

      await waitFor(() => {
        const {id, default_group_storage_quota_mb, default_user_storage_quota_mb} =
          accountWithQuotas
        expect(
          fetchMock.called(ACCOUNT_API_URI, {
            method: 'PUT',
            body: {
              id,
              account: {
                default_group_storage_quota_mb: `${default_group_storage_quota_mb}`,
                default_user_storage_quota_mb: `${default_user_storage_quota_mb}`,
                default_storage_quota_mb: courseQuotaValue,
              },
            },
          }),
        ).toBe(true)
      })
    })
  })

  describe('when account is not a root account', () => {
    const nonRootAccountWithQuotas: AccountWithQuotas = {...accountWithQuotas, root_account: false}

    it('should not show the user quota input', () => {
      render(<DefaultAccountQuotas accountWithQuotas={nonRootAccountWithQuotas} />)
      const userQuota = screen.queryByLabelText(/user quota \*/i)

      expect(userQuota).not.toBeInTheDocument()
    })

    it('should send the correct request when the form is submitted', async () => {
      fetchMock.put(ACCOUNT_API_URI, 200, {overwriteRoutes: true})
      render(<DefaultAccountQuotas accountWithQuotas={nonRootAccountWithQuotas} />)
      const courseQuota = screen.getByLabelText(/course quota \*/i)
      const submit = screen.getByLabelText('Update')
      const courseQuotaValue = '1000'

      await userEvent.clear(courseQuota)
      await userEvent.type(courseQuota, courseQuotaValue)
      await userEvent.click(submit)

      await waitFor(() => {
        const {id, default_group_storage_quota_mb} = accountWithQuotas
        expect(
          fetchMock.called(ACCOUNT_API_URI, {
            method: 'PUT',
            body: {
              id,
              account: {
                default_group_storage_quota_mb: `${default_group_storage_quota_mb}`,
                default_storage_quota_mb: courseQuotaValue,
              },
            },
          }),
        ).toBe(true)
      })
    })
  })
})
