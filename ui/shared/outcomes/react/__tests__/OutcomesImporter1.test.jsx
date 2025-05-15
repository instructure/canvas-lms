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
import moxios from 'moxios'
import {render, cleanup, waitFor, act} from '@testing-library/react'
import OutcomesImporter, {showOutcomesImporterIfInProgress} from '../OutcomesImporter'

import * as alerts from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')

// Use a valid MIME type to encourage multipart/form-data usage
const file = new File(['dummy content'], 'filename.csv', {type: 'text/csv'})
const learningOutcomeGroupId = '3'
const userId = '1'
const contextUrlRoot = '/accounts/' + userId
const getApiUrl = path => `/api/v1${contextUrlRoot}/outcome_imports/${path}`

const getFakeTimer = () =>
  jest.useFakeTimers({
    shouldAdvanceTime: true,
    doNotFake: ['setTimeout'],
    now: new Date('2024-01-01T12:00:00Z'),
  })

const defaultProps = (props = {}) => ({
  hide: () => {},
  disableOutcomeViews: () => {},
  resetOutcomeViews: () => {},
  contextUrlRoot,
  file,
  learningOutcomeGroupId,
  invokedImport: true,
  learningOutcomeGroupAncestorIds: [],
  ...props,
})

// Helper function to render OutcomesImporter with optional mocks
const renderOutcomesImporter = (props = {}, addMocksCallback = () => {}) => {
  const activeProps = {
    ...defaultProps(),
    ...props,
  }
  const ref = React.createRef()
  const container = document.createElement('div')
  document.body.appendChild(container)

  const wrapper = render(<OutcomesImporter {...activeProps} ref={ref} />, {container})

  if (addMocksCallback) {
    addMocksCallback()
  } else {
    // Default stubbed requests
    moxios.stubRequest(getApiUrl(`/group/${learningOutcomeGroupId}?import_type=instructure_csv`), {
      status: 200,
      response: {id: learningOutcomeGroupId},
    })
    moxios.stubRequest(getApiUrl(`outcome_imports/${learningOutcomeGroupId}/created_group_ids`), {
      status: 200,
      response: [],
    })
  }

  return {
    wrapper,
    ref,
    container,
    unmount: () => {
      cleanup()
      container.remove()
    },
  }
}

describe('OutcomesImporter', () => {
  beforeEach(() => {
    moxios.install()
    jest.clearAllMocks()
    jest.clearAllTimers()
  })

  afterEach(() => {
    moxios.uninstall()
    cleanup()
  })

  it('renders the OutcomesImporter component', () => {
    const {wrapper, unmount} = renderOutcomesImporter()
    expect(wrapper.container).toBeInTheDocument()
    unmount()
  })

  it('disables the Outcome Views when upload starts', () => {
    const disableOutcomeViews = jest.fn()
    const {wrapper, unmount} = renderOutcomesImporter({disableOutcomeViews})
    expect(disableOutcomeViews).toHaveBeenCalled()
    unmount()
  })

  it('resets the Outcome Views when upload is complete', done => {
    const resetOutcomeViews = jest.fn()
    const {ref, unmount} = renderOutcomesImporter({resetOutcomeViews, invokedImport: true}, () => {
      // Stub any API calls that might be made during completeUpload
      moxios.stubOnce('GET', new RegExp(`/api/v1${contextUrlRoot}/outcome_imports/.*`), {
        status: 200,
        response: [],
      })
    })

    // Use act to ensure state updates are processed
    act(() => {
      ref.current.completeUpload(null, 10, true)
    })

    // Verify resetOutcomeViews was called synchronously
    expect(resetOutcomeViews).toHaveBeenCalled()
    done()
    unmount()
  })

  it('queries outcomes groups created when upload successfully completes', async () => {
    const id = 10
    const resetOutcomeViews = jest.fn()
    const onSuccessfulOutcomesImport = jest.fn()

    // Use a more flexible URL pattern check
    const createdGroupIdsPattern = new RegExp(
      `/api/v1${contextUrlRoot}/outcome_imports/${id}/created_group_ids`,
    )

    // Setup the mock before rendering the component
    moxios.stubRequest(createdGroupIdsPattern, {
      status: 200,
      response: [],
    })

    const {ref, unmount} = renderOutcomesImporter(
      {resetOutcomeViews, onSuccessfulOutcomesImport, invokedImport: true},
      () => {},
    )

    // Act - use act to ensure state updates are processed
    act(() => {
      ref.current.completeUpload(id, 0, true)
    })

    // Assert - verify resetOutcomeViews was called synchronously
    expect(resetOutcomeViews).toHaveBeenCalled()

    // Wait for the API request to complete
    await waitFor(() => {
      expect(moxios.requests.count()).toBeGreaterThan(0)
    })

    const request = moxios.requests.mostRecent()
    expect(request.url).toContain(`/outcome_imports/${id}/created_group_ids`)

    // Clean up
    unmount()
  })

  it('shows a flash alert when upload successfully completes', () => {
    const resetOutcomeViews = jest.fn()
    const {ref, unmount} = renderOutcomesImporter({resetOutcomeViews})

    ref.current.successfulUpload([])

    expect(alerts.showFlashAlert).toHaveBeenCalledWith({
      type: 'success',
      message: 'Your outcomes were successfully imported.',
    })
    unmount()
  })

  it('shows a flash alert when upload fails', () => {
    const resetOutcomeViews = jest.fn()
    const {ref, unmount} = renderOutcomesImporter({resetOutcomeViews})

    ref.current.completeUpload(null, 1, false)

    expect(alerts.showFlashAlert).toHaveBeenCalledWith({
      type: 'error',
      message:
        'There was an error with your import, please examine your file and attempt the upload again.' +
        ' Check your email for more details.',
    })
    expect(resetOutcomeViews).toHaveBeenCalled()
    unmount()
  })

  it('shows a flash alert when upload successfully completes but with warnings', done => {
    const resetOutcomeViews = jest.fn()
    const {ref, unmount} = renderOutcomesImporter({resetOutcomeViews}, () => {
      moxios.stubRequest(getApiUrl('null/created_group_ids'), {
        status: 200,
        response: [],
      })
    })

    ref.current.completeUpload(null, 10, true)

    moxios.wait(() => {
      expect(alerts.showFlashAlert).toHaveBeenCalledWith({
        type: 'warning',
        message:
          'There was a problem importing some of the outcomes in the uploaded file. Check your email for more details.',
      })
      expect(resetOutcomeViews).toHaveBeenCalled()
      done()
      unmount()
    })
  })
})
