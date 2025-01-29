/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {createRoot} from 'react-dom/client'
import moxios from 'moxios'
import {render, cleanup, waitFor} from '@testing-library/react'
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
  })

  afterEach(() => {
    moxios.uninstall()
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
    const {ref, unmount} = renderOutcomesImporter({resetOutcomeViews})

    ref.current.completeUpload(null, 10, true)

    moxios.wait(() => {
      expect(resetOutcomeViews).toHaveBeenCalled()
      done()
      unmount()
    })
  })

  it('queries outcomes groups created when upload successfully completes', done => {
    const id = 10
    const resetOutcomeViews = jest.fn()
    expect(getApiUrl(`${id}/created_group_ids`)).toBe(
      '/api/v1/accounts/1/outcome_imports/10/created_group_ids',
    )
    const {ref, unmount} = renderOutcomesImporter({resetOutcomeViews}, () => {
      moxios.stubRequest(getApiUrl(`${id}/created_group_ids`), {
        status: 200,
        response: [],
      })
    })

    ref.current.completeUpload(id, 0, true)

    moxios.wait(() => {
      const request = moxios.requests.mostRecent()

      expect(request.url).toBe(getApiUrl(`${id}/created_group_ids`))
      done()
      unmount()
    })
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

  // TODO: redo without moxios
  it('uploads file when the upload begins', done => {
    const disableOutcomeViews = jest.fn()
    const {ref, unmount} = renderOutcomesImporter({disableOutcomeViews}, () => {
      moxios.stubRequest(getApiUrl(`group/${learningOutcomeGroupId}?import_type=instructure_csv`), {
        status: 200,
        response: {id: 3},
      })
    })

    ref.current.beginUpload()

    moxios.wait(() => {
      const request = moxios.requests.mostRecent()

      expect(request.url).toBe(
        getApiUrl(`group/${learningOutcomeGroupId}?import_type=instructure_csv`),
      )

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
    const {wrapper, unmount} = renderOutcomesImporter(
      {disableOutcomeViews, importId: id, file: null},
      () => {
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
    }
    const ref = React.createRef()

    wrapper.rerender(<OutcomesImporter {...newProps} ref={ref} />)
    getFakeTimer()
    ref.current.beginUpload()

    jest.advanceTimersByTime(2000)

    moxios.wait(() => {
      const request = moxios.requests.mostRecent()

      expect(moxios.requests.count()).toEqual(2)
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

  it('starts polling for import status when an import is in progress', async () => {
    const id = '10'
    const disableOutcomeViews = jest.fn()
    const resetOutcomeViews = jest.fn()
    const {ref, unmount} = renderOutcomesImporter({
      disableOutcomeViews,
      resetOutcomeViews,
      importId: id,
      file: null,
    })

    // Mock the first request
    moxios.stubRequest(getApiUrl(id), {
      status: 200,
      response: {workflow_state: 'importing', processing_errors: []},
    })

    // Start polling
    ref.current.pollImportStatus(id)

    // Wait for the first request
    await moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(request.url).toBe(getApiUrl(id))
    })

    // Mock the second request
    moxios.stubRequest(getApiUrl(id), {
      status: 200,
      response: {workflow_state: 'succeeded', processing_errors: []},
    })

    // Wait for the second request and completion
    await moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(request.url).toBe(getApiUrl(id))
      expect(resetOutcomeViews).toHaveBeenCalled()
    })

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
