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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
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

const server = setupServer(
  http.post(getApiUrl(`/group/${learningOutcomeGroupId}`), ({request}) => {
    const url = new URL(request.url)
    if (url.searchParams.get('import_type') === 'instructure_csv') {
      return HttpResponse.json({id: learningOutcomeGroupId})
    }
  }),
  http.get(getApiUrl(`outcome_imports/${learningOutcomeGroupId}/created_group_ids`), () =>
    HttpResponse.json([]),
  ),
  // Generic handler for dynamic outcome import IDs
  http.get(/\/api\/v1\/accounts\/\d+\/outcome_imports\/\d+\/created_group_ids/, () =>
    HttpResponse.json([]),
  ),
)

// Helper function to render OutcomesImporter with optional mocks
const renderOutcomesImporter = (props = {}) => {
  const activeProps = {
    ...defaultProps(),
    ...props,
  }
  const ref = React.createRef()
  const container = document.createElement('div')
  document.body.appendChild(container)

  const wrapper = render(<OutcomesImporter {...activeProps} ref={ref} />, {container})

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
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    cleanup()
    jest.clearAllMocks()
    jest.clearAllTimers()
  })
  afterAll(() => server.close())

  it('uploads file when the upload begins', async () => {
    const disableOutcomeViews = jest.fn()
    const resetOutcomeViews = jest.fn()

    // Create a separate mock for the completeUpload method
    const completeUploadMock = jest.fn()

    let requestReceived = false
    server.use(
      http.post(new RegExp(`/api/v1${contextUrlRoot}/outcome_imports/.*`), async ({request}) => {
        requestReceived = true
        const url = request.url
        expect(url).toContain('/outcome_imports/')
        expect(url).toContain('import_type=instructure_csv')

        const formData = await request.formData()
        expect(formData.get('attachment')).toBeTruthy()

        return HttpResponse.json({id: 10})
      }),
    )

    const {ref, unmount} = renderOutcomesImporter({
      disableOutcomeViews,
      resetOutcomeViews,
      invokedImport: true,
    })

    // Mock the completeUpload method to avoid side effects
    ref.current.completeUpload = completeUploadMock

    // Use act to ensure state updates are processed
    act(() => {
      ref.current.beginUpload()
    })

    // Verify disableOutcomeViews was called synchronously
    expect(disableOutcomeViews).toHaveBeenCalled()

    await waitFor(() => {
      expect(requestReceived).toBe(true)
    })

    unmount()
  })

  it('starts polling for import status after the upload begins', async () => {
    const id = '10'
    const disableOutcomeViews = jest.fn()
    const resetOutcomeViews = jest.fn()

    let requestCount = 0
    server.use(
      http.get(getApiUrl(id), () => {
        requestCount++
        return HttpResponse.json({workflow_state: 'failed', processing_errors: []})
      }),
    )

    const {wrapper, unmount} = renderOutcomesImporter({
      disableOutcomeViews,
      resetOutcomeViews,
      importId: id,
      file: null,
    })
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

    await waitFor(() => {
      expect(requestCount).toBeGreaterThanOrEqual(1)
    })

    jest.clearAllTimers()
    unmount()
  })

  it('completes upload when status returns succeeded or failed', async () => {
    const id = '10'
    const resetOutcomeViews = jest.fn()

    server.use(
      http.get(getApiUrl(id), () =>
        HttpResponse.json({workflow_state: 'succeeded', processing_errors: []}),
      ),
    )

    const {ref, unmount} = renderOutcomesImporter({resetOutcomeViews})

    getFakeTimer()
    ref.current.pollImportStatus(id)

    jest.advanceTimersByTime(2000)

    await waitFor(() => {
      expect(resetOutcomeViews).toHaveBeenCalled()
    })

    unmount()
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

    server.use(
      http.get(getApiUrl('latest'), () =>
        HttpResponse.json({workflow_state: 'importing', user: {id: userId}, id: '1'}),
      ),
    )

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

    server.use(http.get(getApiUrl('latest'), () => new HttpResponse(null, {status: 404})))

    await showOutcomesImporterIfInProgress(props, userId)
    expect(mount.innerHTML).toBe('')
    mount.remove()
  })

  it('queries outcome groups when import completes successfully', async () => {
    const id = '10'
    const resetOutcomeViews = jest.fn()
    const onSuccessfulOutcomesImport = jest.fn()

    let requestMade = false
    server.use(
      http.get(getApiUrl(`${id}/created_group_ids`), () => {
        requestMade = true
        return HttpResponse.json([])
      }),
    )

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
    await waitFor(() => {
      expect(requestMade).toBe(true)
    })

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
