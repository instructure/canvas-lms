/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, waitFor, fireEvent} from '@testing-library/react'
import CSPSelectionBox from '../CSPSelectionBox'

function getFakeApi(getResponse, putResponse, delay, throwError = 'none') {
  return {
    get: () =>
      new Promise((resolve, reject) => {
        if (throwError === 'get' || throwError === 'both') {
          return reject()
        }
        const fakeResponse = {data: getResponse}
        if (delay) {
          setTimeout(() => {
            resolve(fakeResponse)
          }, delay)
        } else {
          resolve(fakeResponse)
        }
      }),
    put: () =>
      new Promise((resolve, reject) => {
        if (throwError === 'put' || throwError === 'both') {
          return reject()
        }
        const fakeResponse = {data: putResponse}
        if (delay) {
          setTimeout(() => resolve(fakeResponse), delay)
        } else {
          resolve(fakeResponse)
        }
      }),
  }
}

beforeEach(() => {
  window.ENV = window.ENV || {}
})

it('removes the loading dialog and replaces it with a checkbox when loaded', async () => {
  expect.assertions(2)
  const fakeAxios = getFakeApi({enabled: false}, {}, 100)
  const {getByText, getByLabelText} = render(
    <CSPSelectionBox courseId="1" apiLibrary={fakeAxios} />
  )
  expect(getByText('Loading')).toBeInTheDocument()
  await waitFor(() => {
    expect(getByLabelText('Disable Content Security Policy')).toBeInTheDocument()
  })
})

it('shows an enabled checkbox when canManage prop is true', async () => {
  expect.assertions(1)
  const fakeAxios = getFakeApi({enabled: false}, {})
  const {getByLabelText} = render(
    <CSPSelectionBox courseId="1" apiLibrary={fakeAxios} canManage={true} />
  )
  await waitFor(() => {
    const checkbox = getByLabelText('Disable Content Security Policy')
    expect(checkbox).not.toBeDisabled()
  })
})

it('shows the checkbox as disabled when canManage is false', async () => {
  expect.assertions(1)
  const fakeAxios = getFakeApi({enabled: false}, {})
  const {getByLabelText} = render(<CSPSelectionBox courseId="1" apiLibrary={fakeAxios} />)
  await waitFor(() => {
    const checkbox = getByLabelText('Disable Content Security Policy')
    expect(checkbox).toBeDisabled()
  })
})

it('sets the csp status to disabled when checked', async () => {
  const fakeAxios = getFakeApi({enabled: true}, {enabled: false})
  const {getByLabelText} = render(
    <CSPSelectionBox courseId="1" apiLibrary={fakeAxios} canManage={true} />
  )
  await waitFor(() => {
    const checkbox = getByLabelText('Disable Content Security Policy')
    fireEvent.click(checkbox)
    expect(checkbox.checked).toBe(true)
  })
})

it('sets the csp status to enabled when unchecked', async () => {
  const fakeAxios = getFakeApi({enabled: false}, {enabled: true})
  const {getByLabelText} = render(
    <CSPSelectionBox courseId="1" apiLibrary={fakeAxios} canManage={true} />
  )
  await waitFor(() => {
    const checkbox = getByLabelText('Disable Content Security Policy')
    fireEvent.click(checkbox)
    expect(checkbox.checked).toBe(false)
  })
})

it('reverts to the previous state if the request fails', async () => {
  const fakeAxios = getFakeApi({enabled: true}, {enabled: false}, null, 'put')
  const {getByLabelText} = render(
    <CSPSelectionBox courseId="1" apiLibrary={fakeAxios} canManage={true} />
  )
  await waitFor(async () => {
    const checkbox = getByLabelText('Disable Content Security Policy')
    fireEvent.click(checkbox)
    await waitFor(() => {
      expect(checkbox.checked).toBe(false)
    })
  })
})

it('shows a failure message if tthe initial get request fails', async () => {
  const fakeAxios = getFakeApi({enabled: true}, {enabled: false}, null, 'get')
  const {getByText} = render(
    <CSPSelectionBox courseId="1" apiLibrary={fakeAxios} canManage={true} />
  )
  await waitFor(() => {
    expect(
      getByText('Failed to load CSP information, try refreshing the page.')
    ).toBeInTheDocument()
  })
})
