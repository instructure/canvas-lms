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
import enzyme from 'enzyme'
import moxios from 'moxios'
import WebZipExportApp from 'ui/features/webzip_export/react/App'

QUnit.module('WebZip Export App', {
  setup() {
    ENV.context_asset_string = 'course_1'
    moxios.install()
  },
  teardown() {
    moxios.uninstall()
  },
})

test('renders a spinner before API call', () => {
  const wrapper = enzyme.shallow(<WebZipExportApp />)
  const node = wrapper.find('Spinner')
  ok(node.exists())
})

test('renders a list of webzip exports', assert => {
  const done = assert.async()
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
  const wrapper = enzyme.shallow(<WebZipExportApp />)
  wrapper.instance().componentDidMount()
  moxios.wait(() => {
    const node = wrapper.find('ExportList')
    ok(node.exists())
    done()
  })
})

test('renders failed exports as well as generated exports', assert => {
  const done = assert.async()
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
  const wrapper = enzyme.shallow(<WebZipExportApp />)
  wrapper.instance().componentDidMount()
  moxios.wait(() => {
    const node = wrapper.find('ExportList')
    equal(node.length, 1)
    done()
  })
})

test('renders empty webzip list text if there are no exports from API', assert => {
  const done = assert.async()
  const data = []
  moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
    status: 200,
    responseText: data,
  })
  ENV.context_asset_string = 'courses_2'
  const wrapper = enzyme.shallow(<WebZipExportApp />)
  wrapper.instance().componentDidMount()
  moxios.wait(() => {
    const node = wrapper.find('ExportList')
    ok(node.exists())
    done()
  })
})

test('does not render empty webzip text if there is an export in progress', assert => {
  const done = assert.async()
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
  const wrapper = enzyme.shallow(<WebZipExportApp />)
  wrapper.instance().componentDidMount()
  moxios.wait(() => {
    const node = wrapper.find('ExportList')
    equal(node.length, 0)
    done()
  })
})

test('render exports and progress bar if both exist', assert => {
  const done = assert.async()
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
  const wrapper = enzyme.shallow(<WebZipExportApp />)
  wrapper.instance().componentDidMount()
  moxios.wait(() => {
    const node1 = wrapper.find('ExportList')
    const node2 = wrapper.find('ExportInProgress')
    ok(node1.exists() && node2.exists())
    done()
  })
})

test('renders errors', assert => {
  const done = assert.async()
  moxios.stubOnce('GET', '/api/v1/courses/2/web_zip_exports', {
    status: 666,
    responseText: 'Demons!',
  })
  ENV.context_asset_string = 'courses_2'
  const wrapper = enzyme.shallow(<WebZipExportApp />)
  wrapper.instance().componentDidMount()
  moxios.wait(() => {
    const node = wrapper.find('Errors')
    ok(node.exists())
    done()
  })
})

test('renders progress bar', assert => {
  const done = assert.async()
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
  const tree = enzyme.shallow(<WebZipExportApp />)
  tree.instance().componentDidMount()
  moxios.wait(() => {
    const node = tree.find('ExportInProgress')
    ok(node.exists())
    done()
  })
})

test('renders different text for newly completed exports', assert => {
  const done = assert.async()
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
  const tree = enzyme.mount(<WebZipExportApp />)
  const app = tree.instance()
  const download = sinon.stub(app, 'downloadLink')
  app.getExports('126')
  moxios.wait(() => {
    tree.update()
    const node = tree.find('ExportList')
    ok(node.text().startsWith('Most recent export: '))
    download.restore()
    done()
  })
})

test('should download a successful export', assert => {
  const done = assert.async()
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
  const tree = enzyme.mount(<WebZipExportApp />)
  const app = tree.instance()
  const download = sinon.stub(app, 'downloadLink')
  app.getExports('126')
  moxios.wait(() => {
    sinon.assert.calledOnce(download)
    download.restore()
    done()
  })
})

QUnit.module('webZipFormat')

test('returns a JS object with necessary info', () => {
  const data = [
    {
      created_at: '2017-01-03T15:55:00Z',
      zip_attachment: {url: 'http://example.com/stuff'},
      workflow_state: 'generated',
      progress_id: '123',
    },
    {
      created_at: '1776-12-25T22:00:00Z',
      zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
      workflow_state: 'generated',
      progress_id: '124',
    },
  ]
  const formatted = WebZipExportApp.webZipFormat(data)
  const expected = [
    {
      date: '1776-12-25T22:00:00Z',
      link: 'http://example.com/washingtoncrossingdelaware',
      workflowState: 'generated',
      progressId: '124',
      newExport: false,
    },
    {
      date: '2017-01-03T15:55:00Z',
      link: 'http://example.com/stuff',
      workflowState: 'generated',
      progressId: '123',
      newExport: false,
    },
  ]
  deepEqual(formatted, expected)
})

test('marks new exports if given progress id', () => {
  const data = [
    {
      created_at: '2017-01-13T12:36:00Z',
      zip_attachment: {url: 'http://example.com/yo'},
      workflow_state: 'generated',
      progress_id: '125',
    },
  ]
  const formatted = WebZipExportApp.webZipFormat(data, '125')
  const expected = [
    {
      date: '2017-01-13T12:36:00Z',
      link: 'http://example.com/yo',
      workflowState: 'generated',
      progressId: '125',
      newExport: true,
    },
  ]
  deepEqual(formatted, expected)
})
