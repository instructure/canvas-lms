/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import sinon from 'sinon'
import WebZipExportApp from '../App'
import {act, render, waitFor} from '@testing-library/react'

describe('Webzip export app', () => {
  beforeEach(() => {
    moxios.install()
  })

  afterEach(() => {
    moxios.uninstall()
  })

  test('renders a spinner before API call', () => {
    ENV.context_asset_string = 'courses_2'
    const wrapper = render(<WebZipExportApp />)
    expect(wrapper.getByText('Loading')).toBeInTheDocument()
  })

  test('renders a list of webzip exports', async () => {
    const data = [
      {
        created_at: '1776-12-25T22:00:00Z',
        zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
        workflow_state: 'generated',
      },
    ]
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data,
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    ref.current.componentDidMount()
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.getByText('Package export from')).toBeInTheDocument()
    })
  })

  test('renders failed exports as well as generated exports', async () => {
    const data = [
      {
        created_at: '1776-12-25T22:00:00Z',
        zip_attachment: {url: null},
        workflow_state: 'failed',
      },
    ]
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data,
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    ref.current.componentDidMount()
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.queryByText('Loading')).toBeInTheDocument()
    })
  })

  test('renders empty webzip list text if there are no exports from API', async () => {
    const data = []
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data,
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    ref.current.componentDidMount()
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.queryByText('No exports to display')).toBeInTheDocument()
    })
  })

  test('does not render empty webzip text if there is an export in progress', async () => {
    const data = [
      {
        created_at: '1776-12-25T22:00:00Z',
        zip_attachment: null,
        workflow_state: 'generating',
        progress_id: '123',
      },
    ]
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data,
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    ref.current.componentDidMount()
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.queryByText('Loading')).toBeNull()
      expect(wrapper.queryByText('No exports to display')).toBeNull()
      expect(wrapper.queryByText('An error occurred. Please try again later.')).toBeNull()
      expect(wrapper.getByText('Processing')).toBeInTheDocument()
    })
  })

  test('render exports and progress bar if both exist', async () => {
    const data = [
      {
        created_at: '2017-01-03T15:55:00Z',
        zip_attachment: {url: 'http://example.com/stuff'},
        workflow_state: 'generating',
        progress_id: '124',
      },
      {
        created_at: '1776-12-25T22:00:00Z',
        zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
        workflow_state: 'generated',
        progress_id: '123',
      },
    ]
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data,
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    ref.current.componentDidMount()
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.queryByText('Loading')).toBeNull()
      expect(wrapper.getByText('Package export from')).toBeInTheDocument()
      expect(wrapper.getByText('Processing')).toBeInTheDocument()
    })
  })

  test('renders errors', async () => {
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 666,
      responseText: 'Demons!',
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    ref.current.componentDidMount()
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.queryByText('Loading')).toBeNull()
      expect(wrapper.getByText('An error occurred. Please try again later.')).toBeInTheDocument()
    })
  })

  test('renders progress bar', async () => {
    const data = [
      {
        created_at: '2017-01-03T15:55:00Z',
        zip_attachment: {url: 'http://example.com/stuff'},
        workflow_state: 'generating',
        progress_id: '124',
      },
    ]
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data,
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    ref.current.componentDidMount()
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.queryByText('Loading')).toBeNull()
      expect(wrapper.getByText('Processing')).toBeInTheDocument()
    })
  })

  test('renders different text for newly completed exports', async () => {
    const data = [
      {
        created_at: '2017-01-13T12:41:00Z',
        zip_attachment: {url: 'http://example.com/thing'},
        workflow_state: 'generated',
        progress_id: '126',
      },
    ]
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data,
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    const download = sinon.stub(ref.current, 'downloadLink')
    act(() => {
      ref.current.getExports('126')
    })
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.queryByText('Loading')).toBeNull()
      expect(wrapper.getByText('Most recent export')).toBeInTheDocument()
      download.restore()
    })
  })

  test('should download a successful export', async () => {
    const data = [
      {
        created_at: '2017-01-13T12:41:00Z',
        zip_attachment: {url: 'http://example.com/thing'},
        workflow_state: 'generated',
        progress_id: '126',
      },
    ]
    moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data,
    })
    ENV.context_asset_string = 'courses_2'
    const ref = React.createRef()
    const wrapper = render(<WebZipExportApp ref={ref} />)
    const download = sinon.stub(ref.current, 'downloadLink')
    act(() => {
      ref.current.getExports('126')
    })
    await waitFor(async () => {
      moxios.requests.mostRecent()
      expect(wrapper.queryByText('Loading')).toBeNull()
      sinon.assert.calledOnce(download)
      download.restore()
    })
  })
})
