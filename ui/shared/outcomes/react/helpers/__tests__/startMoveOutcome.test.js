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

import {waitFor} from '@testing-library/react'
import startMoveOutcome from '../startMoveOutcome'
import * as api from '@canvas/outcomes/graphql/Management'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.useFakeTimers()

describe('startMoveOutcome', () => {
  let showFlashAlertSpy
  const contextType = 'Account'
  const contextId = '1'
  const outcome = {
    _id: '3',
    title: 'Outcome 1'
  }
  const oldParentGroup = {
    id: '2',
    name: 'Group Old'
  }
  const newParentGroup = {
    id: '4',
    name: 'Group New'
  }
  beforeEach(() => {
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('calls moveOutcome with proper arguments', async () => {
    jest.spyOn(api, 'moveOutcome').mockImplementation(() => Promise.resolve({status: 200}))
    startMoveOutcome(contextType, contextId, outcome, oldParentGroup.id, newParentGroup)
    expect(api.moveOutcome).toHaveBeenCalledWith('Account', '1', '3', '2', '4')
  })

  it('shows success flash message when moving an outcome succeeds', async () => {
    jest.spyOn(api, 'moveOutcome').mockImplementation(() => Promise.resolve({status: 200}))
    startMoveOutcome(contextType, contextId, outcome, oldParentGroup.id, newParentGroup)
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"Outcome 1" has been moved to "Group New".',
        type: 'success'
      })
    })
  })

  it('shows custom flash message when moving an outcome fails with error message', async () => {
    jest
      .spyOn(api, 'moveOutcome')
      .mockImplementation(() => Promise.reject(new Error('Network error')))
    startMoveOutcome(contextType, contextId, outcome, oldParentGroup.id, newParentGroup)
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred moving outcome "Outcome 1": Network error',
        type: 'error'
      })
    })
  })

  it('shows default flash message when moving an outcome fails without error message', async () => {
    jest.spyOn(api, 'moveOutcome').mockImplementation(() => Promise.reject(new Error()))
    startMoveOutcome(contextType, contextId, outcome, oldParentGroup.id, newParentGroup)
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred moving outcome "Outcome 1"',
        type: 'error'
      })
    })
  })
})
