/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'
import bridge from '../../../../../bridge'
import doFileUpload from '../doFileUpload'
import {act, getAllByLabelText, getAllByText, getByText, waitFor} from '@testing-library/react'

jest.mock('react-dom', () => ({
  ...jest.requireActual('react-dom'),
  unmountComponentAtNode: jest.fn(),
}))

const fauxEditor = {
  focus: () => {},
  settings: {
    canvas_rce_user_context: {
      type: 'course',
      id: '17',
    },
  },
}

describe('doFileUpload()', () => {
  let trayProps
  beforeEach(() => {
    trayProps = {
      source: {
        initializeCollection() {},
        initializeUpload() {},
        initializeFlickr() {},
        initializeImages() {},
        initializeDocuments() {},
        initializeMedia() {},
      },
    }
    bridge.trayProps.set(fauxEditor, trayProps)
  })
  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('adds the canvas-rce-upload-container element when opened', async () => {
    await doFileUpload(fauxEditor, document, {
      accept: undefined,
      panels: ['COMPUTER', 'URL'],
      preselectedFile: undefined,
    }).shownPromise
    expect(document.querySelector('.canvas-rce-upload-container')).toBeTruthy()
  })

  it('does not add the canvas-rce-upload-container element when opened if it exists already', async () => {
    const container = document.createElement('div')
    container.className = 'canvas-rce-upload-container'
    document.body.appendChild(container)
    await doFileUpload(fauxEditor, document, {
      accept: undefined,
      panels: ['COMPUTER'],
      preselectedFile: undefined,
    }).shownPromise
    expect(document.querySelectorAll('.canvas-rce-upload-container').length).toEqual(1)
  })

  it('opens the Upload Image modal when called with "image/*', async () => {
    await doFileUpload(fauxEditor, document, {
      accept: 'image/*',
      panels: ['COMPUTER'],
      preselectedFile: undefined,
    }).shownPromise
    expect(
      getAllByLabelText(document, 'Upload Image', {
        selector: '[role="dialog"]',
      })[0]
    ).toBeVisible()
  })

  it('opens the Upload File modal when called with accept any', async () => {
    await doFileUpload(fauxEditor, document, {
      accept: undefined,
      panels: ['COMPUTER'],
      preselectedFile: undefined,
    }).shownPromise
    expect(
      getAllByLabelText(document, 'Upload File', {
        selector: '[role="dialog"]',
      })[0]
    ).toBeVisible()
  })

  it('dismounts the modal when dismissed', async () => {
    await doFileUpload(fauxEditor, document, {
      accept: undefined,
      panels: ['COMPUTER'],
      preselectedFile: undefined,
    }).shownPromise
    expect(
      getAllByLabelText(document, 'Upload File', {
        selector: '[role="dialog"]',
      })[0]
    ).toBeVisible()

    const closeBtn = getAllByText(document, 'Close')[0].closest('button')
    act(() => {
      closeBtn.click()
    })
    expect(ReactDOM.unmountComponentAtNode).toHaveBeenCalled()
  })

  describe('opens the Upload modal with the requested tabs', () => {
    it('when requesting two', async () => {
      await doFileUpload(fauxEditor, document, {
        accept: 'image/*',
        panels: ['COMPUTER', 'URL'],
        preselectedFile: undefined,
      }).shownPromise
      await waitFor(() => {
        expect(document.querySelectorAll('[role="tab"]').length).toEqual(2)
      })
      expect(
        getByText(document, 'Computer', {
          selector: '[role="tab"]',
        })
      ).toBeVisible()
      expect(
        getByText(document, 'URL', {
          selector: '[role="tab"]',
        })
      ).toBeVisible()
    })

    it('when requesting one', async () => {
      await doFileUpload(fauxEditor, document, {
        accept: 'image/*',
        panels: ['URL'],
        preselectedFile: undefined,
      }).shownPromise
      await waitFor(() => {
        expect(document.querySelectorAll('[role="tab"]').length).toEqual(1)
      })
      expect(
        getByText(document, 'URL', {
          selector: '[role="tab"]',
        })
      ).toBeVisible()
    })
  })
})
