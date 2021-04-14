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

import {render, act, fireEvent} from '@testing-library/react'
import React from 'react'
import Integrations from '../Integrations'
import axios from 'axios'
import useFetchApi from '@canvas/use-fetch-api-hook'

jest.mock('@canvas/use-fetch-api-hook')
jest.mock('axios')

describe('Integrations', () => {
  const oldENV = window.ENV

  beforeEach(() => {
    window.ENV = {
      COURSE_ID: 2
    }
  })

  afterEach(() => {
    axios.request.mockClear()
    useFetchApi.mockClear()
    window.ENV = oldENV
  })

  it('renders the Microsoft Sync integration', () => {
    const subject = render(<Integrations />)
    expect(subject.getAllByText('Microsoft Sync')).toBeTruthy()
  })

  describe('Microsoft Sync', () => {
    it('shows errors when they exist', () => {
      useFetchApi.mockImplementationOnce(({error, loading}) => {
        error({message: 'error', response: {status: 500}})
        loading(false)
      })

      const subject = render(<Integrations />)
      expect(
        subject.getByText('An error occurred, please try again. Error: error')
      ).toBeInTheDocument()
    })

    it('disables the integration when toggled', () => {
      useFetchApi.mockImplementationOnce(({success, loading}) => {
        success({workflow_state: 'active'})
        loading(false)
      })

      const subject = render(<Integrations />)

      act(() => {
        fireEvent.click(subject.getByLabelText('Toggle Microsoft Sync'))
      })

      expect(axios.request).toHaveBeenLastCalledWith({
        method: 'delete',
        url: `/api/v1/courses/2/microsoft_sync/group`
      })
      expect(subject.getByLabelText('Toggle Microsoft Sync').checked).toBeTruthy()
    })

    it('renders a sync button', () => {
      useFetchApi.mockImplementationOnce(({success, loading}) => {
        success({workflow_state: 'active'})
        loading(false)
      })

      const subject = render(<Integrations />)

      act(() => {
        fireEvent.click(subject.getByText('Show Microsoft Sync details'))
      })

      expect(subject.getByText('Sync Now')).toBeTruthy()
    })

    describe('when the integration is disabled', () => {
      beforeEach(() => {
        useFetchApi.mockImplementationOnce(({success, loading}) => {
          success({})
          loading(false)
        })
      })

      it('enables the integration when toggled', () => {
        const subject = render(<Integrations />)

        act(() => {
          fireEvent.click(subject.getByLabelText('Toggle Microsoft Sync'))
        })

        expect(axios.request).toHaveBeenLastCalledWith({
          method: 'post',
          url: `/api/v1/courses/2/microsoft_sync/group`
        })

        expect(subject.getByLabelText('Toggle Microsoft Sync').checked).toBeFalsy()
      })
    })
  })
})
