/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {render, act, fireEvent, waitFor} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import MicrosoftSyncButton from '../MicrosoftSyncButton'
import React from 'react'

jest.mock('@canvas/do-fetch-api-effect')

describe('MicrosoftSyncButton', () => {
  const props = overrides => ({
    enabled: true,
    group: {
      id: 10,
      course_id: 17,
      workflow_state: 'pending',
      job_state: null,
      last_synced_at: null,
      last_manually_synced_at: null,
      last_error: null,
      root_account_id: 1,
      created_at: '2021-03-30T20:52:22Z',
      updated_at: '2021-03-30T20:52:38Z',
      ms_group_id: '1444b70c-270b-444a-9120-9c7efbabf7a6',
    },
    onError: () => {},
    onSuccess: () => {},
    onInfo: () => {},
    courseId: 14,
    ...overrides,
  })
  const subject = overrides => render(<MicrosoftSyncButton {...props(overrides)} />)

  it('renders an enabled sync button', () => {
    expect(subject().getByText('Sync Now').closest('button').disabled).toBeFalsy()
  })

  it('schedules a sync on click', () => {
    const component = subject()
    doFetchApi.mockImplementationOnce(() => Promise.resolve({json: props().group}))

    act(() => {
      fireEvent.click(component.getByText('Sync Now'))
    })

    expect(doFetchApi).toHaveBeenLastCalledWith({
      method: 'POST',
      path: `/api/v1/courses/${props().courseId}/microsoft_sync/schedule_sync`,
    })
  })

  describe('when it is not enabled', () => {
    const overrides = {enabled: false}

    it('does not enable the sync button', () => {
      expect(subject(overrides).getByText('Sync Now').closest('button').disabled).toBeTruthy()
    })
  })

  describe('when the sync request is loading', () => {
    beforeEach(() =>
      doFetchApi.mockImplementationOnce(() => Promise.resolve({json: props().group}))
    )

    it('shows a "scheduling sync" spinner', () => {
      const component = subject()

      act(() => {
        fireEvent.click(component.getByText('Sync Now'))
      })

      expect(component.getByText('Scheduling sync')).toBeInTheDocument()
      expect(component.getByText('Scheduling sync').closest('button').disabled).toBeTruthy()
    })
  })

  describe('when the sync request fails', () => {
    beforeEach(() =>
      doFetchApi.mockImplementationOnce(() =>
        // eslint-disable-next-line prefer-promise-reject-errors
        Promise.reject({message: 'test error'})
      )
    )

    it('calls the error handler, but allows trying to sync again', async () => {
      const onError = jest.fn()

      const component = subject({onError})
      fireEvent.click(component.getByText('Sync Now'))

      await waitFor(() => expect(onError).toHaveBeenCalled())
    })

    it('enables the sync button', async () => {
      const component = subject()
      fireEvent.click(component.getByText('Sync Now'))
      await waitFor(() =>
        expect(component.getByText('Sync Now').closest('button').disabled).toBeFalsy()
      )
    })

    describe('and then succeeds on retry', () => {
      const onSuccess = jest.fn()
      const onError = jest.fn()

      afterEach(() => {
        onSuccess.mockClear()
        onError.mockClear()
      })

      it('clears the first error', async () => {
        const component = subject({onError, onSuccess})

        // The first attempt fails
        fireEvent.click(component.getByText('Sync Now'))
        await waitFor(() => expect(onError).toHaveBeenCalled())

        // The second attempt succeeds
        doFetchApi.mockImplementationOnce(() => Promise.resolve({json: props().group}))
        fireEvent.click(component.getByText('Sync Now'))
        await waitFor(() => expect(onSuccess).toHaveBeenCalled())

        // onError should have been called again, this time removing the error
        await waitFor(() => expect(onError).toHaveBeenLastCalledWith(false))
      })
    })
  })

  describe('when the sync request succeeds', () => {
    const oldEnv = window.ENV
    beforeEach(() => {
      doFetchApi.mockImplementationOnce(() => Promise.resolve({json: props().group}))
      window.ENV = {
        MSFT_SYNC_CAN_BYPASS_COOLDOWN: false,
      }
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('shows a success message and disables the sync button', async () => {
      const onSuccess = jest.fn()

      const component = subject({onSuccess})
      fireEvent.click(component.getByText('Sync Now'))

      await waitFor(() => expect(onSuccess).toHaveBeenCalled())
    })

    it('disables the sync button', async () => {
      const component = subject()
      fireEvent.click(component.getByText('Sync Now'))
      await waitFor(() =>
        expect(component.getByText('Sync Now').closest('button').disabled).toBeTruthy()
      )
    })
  })

  describe('when the cool down period has not passed', () => {
    const onInfo = jest.fn()
    const overrides = {
      group: {
        ...props().group,
        last_manually_synced_at: new Date(),
        workflow_state: 'completed',
      },
      onInfo,
    }
    const oldENV = window.ENV

    beforeEach(() => {
      window.ENV = {
        MANUAL_MSFT_SYNC_COOLDOWN: 5400, // 90 minutes
        MSFT_SYNC_CAN_BYPASS_COOLDOWN: false,
      }
    })
    afterEach(() => (window.ENV = oldENV))

    it('shows a countdown indicating when the next manual sync may occur', async () => {
      subject(overrides)
      await waitFor(() =>
        expect(onInfo).toHaveBeenLastCalledWith(
          expect.stringMatching(
            /Manual syncs are available every 90 minutes. Please wait 90 minutes to sync again./
          )
        )
      )
    })

    it('disables the sync button', async () => {
      const component = subject(overrides)
      await waitFor(() =>
        expect(component.getByText('Sync Now').closest('button').disabled).toBeTruthy()
      )
    })

    describe('and the user is a site admin', () => {
      const oldEnv = window.ENV
      beforeEach(() => {
        window.ENV = {
          MSFT_SYNC_CAN_BYPASS_COOLDOWN: true,
          MANUAL_MSFT_SYNC_COOLDOWN: 5400, // 90 minutes
        }
      })

      afterEach(() => {
        window.ENV = oldEnv
      })

      it('ignores the cooldown period', () => {
        const container = subject(overrides)

        expect(container.getByText(/sync now/i).closest('button')).not.toBeDisabled()
      })
    })

    describe('and the group is in an error state', () => {
      it('enables the sync button', async () => {
        const component = subject({
          ...overrides,
          group: {
            ...props().group,
            workflow_state: 'errored',
          },
        })

        await waitFor(() =>
          expect(component.getByText('Sync Now').closest('button').disabled).toBeFalsy()
        )
      })
    })
  })
})
