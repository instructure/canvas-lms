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

  // TODO: redo without moxios
  it('uploads file when the upload begins', done => {
    const disableOutcomeViews = jest.fn()
    const resetOutcomeViews = jest.fn()

    // Create a separate mock for the completeUpload method
    const completeUploadMock = jest.fn()

    const {ref, unmount} = renderOutcomesImporter(
      {disableOutcomeViews, resetOutcomeViews, invokedImport: true},
      () => {
        // Use a wildcard stub to catch any URL format for the outcome_imports endpoint
        moxios.stubOnce('POST', new RegExp(`/api/v1${contextUrlRoot}/outcome_imports/.*`), {
          status: 200,
          response: {id: 10},
        })
      },
    )

    // Mock the completeUpload method to avoid side effects
    ref.current.completeUpload = completeUploadMock

    // Use act to ensure state updates are processed
    act(() => {
      ref.current.beginUpload()
    })

    // Verify disableOutcomeViews was called synchronously
    expect(disableOutcomeViews).toHaveBeenCalled()

    moxios.wait(() => {
      const request = moxios.requests.mostRecent()

      // Verify the URL contains the expected path components without being strict about the format
      expect(request.url).toContain('/outcome_imports/')
      expect(request.url).toContain('import_type=instructure_csv')

      // Since moxios doesn't parse FormData, we'll inspect the FormData manually
      // Access the FormData entries via Symbols
      const symbols = Object.getOwnPropertySymbols(request.config.data)
      const entries = request.config.data[symbols[0]]

      // Find the attachment entry
      const attachmentEntry = entries.find(entry => entry.name === 'attachment')

      expect(attachmentEntry).toBeDefined()
      // Since moxios serializes the File, attachmentEntry.value is "[object File]"
      // We cannot assert it is an instance of File, so we'll check the serialized string
      expect(attachmentEntry.value).toBe('[object File]')
      done()
      unmount()
    })
  })

  it('starts polling for import status after the upload begins', done => {
    const id = '10'
    const disableOutcomeViews = jest.fn()
    const resetOutcomeViews = jest.fn()
    const {wrapper, unmount} = renderOutcomesImporter(
      {disableOutcomeViews, resetOutcomeViews, importId: id, file: null},
      () => {
        // Stub the request for polling with the correct URL
        moxios.stubRequest(getApiUrl(id), {
          status: 200,
          response: {workflow_state: 'failed', processing_errors: []},
        })
      },
    )
    const newProps = {
      ...defaultProps(),
      file: null,
      importId: id,
      resetOutcomeViews,
    }
    const ref = React.createRef()

    wrapper.rerender(<OutcomesImporter {...newProps} ref={ref} />)
    getFakeTimer()
    ref.current.beginUpload()

    jest.advanceTimersByTime(2000)

    moxios.wait(() => {
      const request = moxios.requests.mostRecent()

      // Verify the request count
      expect(moxios.requests.count()).toEqual(2)

      // Check that the URL matches what's expected by the apiClient
      expect(request.url).toBe(getApiUrl(id))

      jest.clearAllTimers()
      done()
      unmount()
    })
  })

  it('completes upload when status returns succeeded or failed', done => {
    const id = '10'
    const resetOutcomeViews = jest.fn()
    const {ref, unmount} = renderOutcomesImporter({resetOutcomeViews}, () => {
      moxios.stubRequest(getApiUrl(id), {
        status: 200,
        response: {workflow_state: 'succeeded', processing_errors: []},
      })
    })

    getFakeTimer()
    ref.current.pollImportStatus(id)

    jest.advanceTimersByTime(2000)

    moxios.wait(() => {
      expect(resetOutcomeViews).toHaveBeenCalled()
      done()
      unmount()
    })
  })

  it('renders importer if in progress', async () => {
    const mount = document.createElement('div')
    document.body.appendChild(mount)
    const props = {
      mount,
      contextUrlRoot,
      disableOutcomeViews: () => {},
      resetOutcomeViews: () => {},
    }

    moxios.stubRequest(getApiUrl('latest'), {
      status: 200,
      response: {workflow_state: 'importing', user: {id: userId}, id: '1'},
    })

    await showOutcomesImporterIfInProgress(props, userId)
    await waitFor(() => {
      expect(mount.innerHTML).not.toBe('')
    })
    mount.remove()
  })

  it('does not render importer if no latest import', async () => {
    const mount = document.createElement('div')
    document.body.appendChild(mount)
    const props = {
      mount,
      contextUrlRoot,
      disableOutcomeViews: () => {},
      resetOutcomeViews: () => {},
    }

    moxios.stubRequest(getApiUrl('latest'), {
      status: 404,
    })

    await showOutcomesImporterIfInProgress(props, userId)
    expect(mount.innerHTML).toBe('')
    mount.remove()
  })

  it('queries outcome groups when import completes successfully', async () => {
    const id = '10'
    const resetOutcomeViews = jest.fn()
    const onSuccessfulOutcomesImport = jest.fn()

    // Setup the mock for created_group_ids endpoint
    moxios.stubRequest(getApiUrl(`${id}/created_group_ids`), {
      status: 200,
      response: [],
    })

    // Render with the necessary props
    const {ref, unmount} = renderOutcomesImporter({
      resetOutcomeViews,
      onSuccessfulOutcomesImport,
      invokedImport: true,
    })

    // Trigger the completeUpload method directly with a successful state
    act(() => {
      ref.current.completeUpload(id, 0, true)
    })

    // Verify resetOutcomeViews was called synchronously
    expect(resetOutcomeViews).toHaveBeenCalled()

    // Wait for the API request to be made
    await moxios.wait(() => {})

    // Verify the request was made with the correct URL
    const request = moxios.requests.mostRecent()
    expect(request.url).toContain(`/outcome_imports/${id}/created_group_ids`)

    // Verify onSuccessfulOutcomesImport was called
    await waitFor(() => {
      expect(onSuccessfulOutcomesImport).toHaveBeenCalled()
    })

    // Clean up
    unmount()
  }, 15000) // Increase timeout to handle async operations

  it('displays "please wait" text for user that invoked upload', () => {
    const {wrapper, unmount} = renderOutcomesImporter()

    expect(wrapper.getByText('Please wait as we upload and process your file.')).toBeInTheDocument()
    unmount()
  })

  it('displays "ok to leave" text for user that invoked upload', () => {
    const {wrapper, unmount} = renderOutcomesImporter()

    expect(
      wrapper.getByText("It's ok to leave this page, we'll email you when the import is done."),
    ).toBeInTheDocument()
    unmount()
  })

  it('displays "currently in progress" text for user that did not invoke the upload', () => {
    const {wrapper, unmount} = renderOutcomesImporter({invokedImport: false})

    expect(wrapper.getByText('An outcome import is currently in progress.')).toBeInTheDocument()
    unmount()
  })

  it('properly cleans up when unmounted', () => {
    const {unmount, container} = renderOutcomesImporter()
    unmount()
    expect(container.innerHTML).toBe('')
  })
})
