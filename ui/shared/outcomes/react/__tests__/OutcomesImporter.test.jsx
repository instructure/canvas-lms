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
import ReactDOM from 'react-dom'
import moxios from 'moxios'
import {render, cleanup} from '@testing-library/react'
import OutcomesImporter, {showOutcomesImporterIfInProgress} from '../OutcomesImporter'

import * as alerts from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')

const file = new File([], 'filename')
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
  file,
  contextUrlRoot,
  learningOutcomeGroupId,
  invokedImport: true,
  learningOutcomeGroupAncestorIds: [],
  ...props,
})

const renderOutcomesImporter = (props = {}, addMocksCallback = () => {}) => {
  const activeProps = {
    ...defaultProps(),
    ...props,
  }
  const ref = React.createRef()

  const wrapper = render(<OutcomesImporter {...activeProps} ref={ref} />)

  if (addMocksCallback) {
    addMocksCallback()
  } else {
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
  }
}

describe('OutcomesImporter', () => {
  beforeEach(() => {
    moxios.install()
  })

  afterEach(() => {
    cleanup()
    moxios.uninstall()
  })

  it('renders the OutcomesImporter component', () => {
    const {wrapper} = renderOutcomesImporter()

    expect(wrapper.container).toBeInTheDocument()
  })

  it('disables the Outcome Views when upload starts', done => {
    const disableOutcomeViews = jest.fn()
    const {ref} = renderOutcomesImporter({disableOutcomeViews})

    ref.current.beginUpload()

    moxios.wait(() => {
      expect(disableOutcomeViews).toHaveBeenCalled()
      done()
    })
  })

  it('resets the Outcome Views when upload is complete', done => {
    const resetOutcomeViews = jest.fn()
    const {ref} = renderOutcomesImporter({resetOutcomeViews})

    ref.current.completeUpload(null, 10, true)

    moxios.wait(() => {
      expect(resetOutcomeViews).toHaveBeenCalled()
      done()
    })
  })

  it('queries outcomes groups created when upload successfully completes', done => {
    const id = 10
    const resetOutcomeViews = jest.fn()
    expect(getApiUrl(`${id}/created_group_ids`)).toBe(
      '/api/v1/accounts/1/outcome_imports/10/created_group_ids'
    )
    const {ref} = renderOutcomesImporter({resetOutcomeViews}, () => {
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
    })
  })

  it('shows a flash alert when upload successfully completes', () => {
    const resetOutcomeViews = jest.fn()
    const {ref} = renderOutcomesImporter({resetOutcomeViews})

    ref.current.successfulUpload([])

    expect(alerts.showFlashAlert).toHaveBeenCalledWith({
      type: 'success',
      message: 'Your outcomes were successfully imported.',
    })
  })

  it('shows a flash alert when upload fails', () => {
    const resetOutcomeViews = jest.fn()
    const {ref} = renderOutcomesImporter({resetOutcomeViews})

    ref.current.completeUpload(null, 1, false)

    expect(alerts.showFlashAlert).toHaveBeenCalledWith({
      type: 'error',
      message:
        'There was an error with your import, please examine your file and attempt the upload again.' +
        ' Check your email for more details.',
    })
    expect(resetOutcomeViews).toHaveBeenCalled()
  })

  it('shows a flash alert when upload successfully completes but with warnings', done => {
    const resetOutcomeViews = jest.fn()
    const {ref} = renderOutcomesImporter({resetOutcomeViews}, () => {
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
    })
  })

  it('uploads file when the upload begins', done => {
    const disableOutcomeViews = jest.fn()
    const {ref} = renderOutcomesImporter({disableOutcomeViews}, () => {
      moxios.stubRequest(
        getApiUrl(`/group/${learningOutcomeGroupId}?import_type=instructure_csv`),
        {
          status: 200,
          response: {id: 3},
        }
      )
    })

    ref.current.beginUpload()

    moxios.wait(() => {
      const request = moxios.requests.mostRecent()

      expect(request.url).toBe(
        getApiUrl(`/group/${learningOutcomeGroupId}?import_type=instructure_csv`)
      )
      expect(request.config.data.get('attachment')).toEqual(file)
      done()
    })
  })

  it('starts polling for import status after the upload begins', done => {
    const id = '10'
    const disableOutcomeViews = jest.fn()
    const {wrapper} = renderOutcomesImporter({disableOutcomeViews}, () => {
      moxios.stubRequest(getApiUrl(id), {
        status: 200,
        response: {workflow_state: 'failed', processing_errors: []},
      })
    })
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

      expect(moxios.requests.count()).toEqual(3)
      expect(request.url).toBe(getApiUrl(id))
      jest.clearAllTimers()
      done()
    })
  })

  it('completes upload when status returns succeeded or failed', done => {
    const id = '10'
    const resetOutcomeViews = jest.fn()
    const {ref} = renderOutcomesImporter({resetOutcomeViews}, () => {
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
    })
  })

  it('renders importer if in progress', done => {
    const props = defaultProps()

    moxios.stubRequest(getApiUrl('latest'), {
      status: 200,
      response: {workflow_state: 'importing', user: {id: userId}},
    })
    jest.spyOn(ReactDOM, 'render')

    showOutcomesImporterIfInProgress(props, userId)

    moxios.wait(() => {
      expect(ReactDOM.render).toHaveBeenCalled()
      done()
    })
  })

  it('does not render importer if no latest import', done => {
    const props = defaultProps()
    moxios.stubRequest(getApiUrl('latest'), {
      status: 404,
    })
    jest.spyOn(ReactDOM, 'render')

    showOutcomesImporterIfInProgress(props, userId)

    moxios.wait(() => {
      expect(ReactDOM.render).not.toHaveBeenCalled()
      done()
    })
  })

  it('starts polling for import status when an import is in progress', done => {
    const importId = '9'
    const disableOutcomeViews = jest.fn()
    const {ref} = renderOutcomesImporter({disableOutcomeViews, importId, file: null}, () => {
      moxios.stubRequest(getApiUrl(importId), {
        status: 200,
        response: {},
      })
    })
    getFakeTimer()
    ref.current.beginUpload()

    jest.advanceTimersByTime(3000)

    moxios.wait(() => {
      const request = moxios.requests.mostRecent()

      expect(moxios.requests.count()).toEqual(3)
      expect(request.url).toBe(getApiUrl(importId))
      done()
    })
  })

  it('display "please wait" text for user that invoked upload', () => {
    const {wrapper} = renderOutcomesImporter()

    expect(wrapper.getByText('Please wait as we upload and process your file.')).toBeInTheDocument()
  })

  it('display "ok to leave" text for user that invoked upload', () => {
    const {wrapper} = renderOutcomesImporter()

    expect(
      wrapper.getByText("It's ok to leave this page, we'll email you when the import is done.")
    ).toBeInTheDocument()
  })

  it('display "currently in progress" text for user that did not invoke the upload', () => {
    const {wrapper} = renderOutcomesImporter({invokedImport: false})

    expect(wrapper.getByText('An outcome import is currently in progress.')).toBeInTheDocument()
  })
})
