/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {CompletionProgressBar, buildProgressCellContent} from '../completion_progress_bar'

jest.mock('@canvas/do-fetch-api-effect')

const renderComponent = (overrideProps?: any) =>
  render(<CompletionProgressBar progress_url="https://mock.progress.url" {...overrideProps} />)

describe('CompletionProgressBar', () => {
  afterEach(() => jest.clearAllMocks())

  it('renders with the correct progress', async () => {
    doFetchApi.mockImplementation(() => Promise.resolve({json: {completion: 75.0}}))
    const component = renderComponent()
    await waitFor(() => expect(component.getByRole('progressbar')).toBeInTheDocument())
    expect(component.getByRole('progressbar')).toHaveAttribute('value', '75')
  })

  it('updates bar with the progress', async () => {
    jest.useFakeTimers()
    let updates = 0
    doFetchApi.mockImplementation(() => {
      updates++
      let completion
      if (updates === 1) completion = 0
      if (updates === 2) completion = 25
      if (updates === 3) completion = 50
      if (updates === 4) completion = 75
      if (updates > 4) completion = 100
      return Promise.resolve({json: {completion}})
    })
    const component = renderComponent()
    await waitFor(() => expect(component.getByRole('progressbar')).toHaveAttribute('value', '0'))

    jest.advanceTimersByTime(1000)
    await waitFor(() => expect(component.getByRole('progressbar')).toHaveAttribute('value', '25'))

    jest.advanceTimersByTime(1000)
    await waitFor(() => expect(component.getByRole('progressbar')).toHaveAttribute('value', '50'))

    jest.advanceTimersByTime(1000)
    await waitFor(() => expect(component.getByRole('progressbar')).toHaveAttribute('value', '75'))

    jest.advanceTimersByTime(1000)
    await waitFor(() => expect(component.getByRole('progressbar')).toHaveAttribute('value', '100'))

    expect(doFetchApi).toHaveBeenCalledTimes(5)
    jest.useRealTimers()
  })

  it('does not render when progress completes', async () => {
    jest.useFakeTimers()
    let updates = 0
    doFetchApi.mockImplementation(() => {
      updates++
      let completion = 100
      if (updates === 1) completion = 0
      if (updates === 2) completion = 25
      if (updates === 3) completion = 50
      if (updates === 4) completion = 75
      const workflow_state = completion >= 100 ? 'completed' : 'running'
      return Promise.resolve({
        json: {completion, workflow_state},
      })
    })
    const component = renderComponent()
    await waitFor(() => expect(component.getByRole('progressbar')).toBeInTheDocument())
    jest.advanceTimersByTime(4000)
    await waitFor(() => expect(component.container).toBeEmptyDOMElement())
    jest.useRealTimers()
  })

  it('does not render when progress fails', async () => {
    jest.useFakeTimers()
    let updates = 0
    doFetchApi.mockImplementation(() => {
      updates++
      let completion = 50
      if (updates === 1) completion = 0
      if (updates === 2) completion = 25
      const workflow_state = completion >= 50 ? 'failed' : 'running'
      return Promise.resolve({
        json: {completion, workflow_state},
      })
    })
    const component = renderComponent()
    await waitFor(() => expect(component.getByRole('progressbar')).toBeInTheDocument())
    jest.advanceTimersByTime(4000)
    await waitFor(() => expect(component.container).toBeEmptyDOMElement())
    jest.useRealTimers()
  })

  it('does not render if url does not exist', () => {
    const component = renderComponent({progress_url: ''})
    expect(component.container).toBeEmptyDOMElement()
  })

  it('does not render if fetch fails', () => {
    doFetchApi.mockImplementation(() => Promise.reject())
    const component = renderComponent()
    expect(component.container).toBeEmptyDOMElement()
  })

  it('does not render if response is null', () => {
    doFetchApi.mockImplementation(() => Promise.resolve({json: null}))
    const component = renderComponent()
    expect(component.container).toBeEmptyDOMElement()
  })

  it('does not render if completed', () => {
    doFetchApi.mockImplementation(() => {
      return Promise.resolve({json: {completion: 100.0, workflow_state: 'completed'}})
    })
    const component = renderComponent()
    expect(component.container).toBeEmptyDOMElement()
  })

  it('does not render if failed', () => {
    doFetchApi.mockImplementation(() => {
      return Promise.resolve({json: {completion: 100.0, workflow_state: 'failed'}})
    })
    const component = renderComponent()
    expect(component.container).toBeEmptyDOMElement()
  })
})

describe('buildProgressCellContent()', () => {
  it('renders text', () => {
    const component = render(buildProgressCellContent('failed', 5, 'https://mock.progress.url'))
    expect(component.getByText('5 issues')).toBeInTheDocument()
  })

  it('renders progress bar', async () => {
    doFetchApi.mockImplementation(() => Promise.resolve({json: {completion: 75.0}}))
    const component = render(buildProgressCellContent('running', 0, 'https://mock.progress.url'))
    await waitFor(() => expect(component.getByRole('progressbar')).toBeInTheDocument())
    expect(component.getByRole('progressbar')).toHaveAttribute('value', '75')
  })
})
