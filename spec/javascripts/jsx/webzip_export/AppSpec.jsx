define([
  'react',
  'enzyme',
  'moxios',
  'jsx/webzip_export/App',
], (React, enzyme, moxios, WebZipExportApp) => {
  module('WebZip Export App', {
    setup () {
      moxios.install()
    },
    teardown () {
      moxios.uninstall()
    }
  })

  test('renders a spinner before API call', () => {
    const wrapper = enzyme.shallow(<WebZipExportApp />)
    const node = wrapper.find('Spinner')
    ok(node.exists())
  })

  test('renders a list of webzip exports', (assert) => {
    const done = assert.async()
    const data = [{
      created_at: '1776-12-25T22:00:00Z',
      zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
      workflow_state: 'generated',
    }]
    moxios.stubRequest('/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data
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

  test('renders empty webzip list text if there are no exports from API', (assert) => {
    const done = assert.async()
    const data = []
    moxios.stubRequest('/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data
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

  test('does not render empty webzip text if there is an export in progress', (assert) => {
    const done = assert.async()
    const data = [{
      created_at: '1776-12-25T22:00:00Z',
      zip_attachment: null,
      workflow_state: 'generating'
    }]
    moxios.stubRequest('/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data
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

  test('renders errors', (assert) => {
    const done = assert.async()
    moxios.stubRequest('/api/v1/courses/2/web_zip_exports', {
      status: 666,
      responseText: 'Demons!'
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

  test('renders progress bar', (assert) => {
    const done = assert.async()
    const data = [{
      created_at: '2017-01-03T15:55Z',
      zip_attachment: {url: 'http://example.com/stuff'},
      workflow_state: 'generating',
    }]
    moxios.stubRequest('/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data
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

  module('webZipFormat')

  test('returns a JS object with necessary info', () => {
    const data = [{
      created_at: '2017-01-03T15:55Z',
      zip_attachment: {url: 'http://example.com/stuff'},
      workflow_state: 'generated',
      progress_id: '123'
    },
    {
      created_at: '1776-12-25T22:00Z',
      zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
      workflow_state: 'generated',
      progress_id: '124'
    }]
    const formatted = WebZipExportApp.webZipFormat(data)
    const expected = [{
      date: '1776-12-25T22:00Z',
      link: 'http://example.com/washingtoncrossingdelaware',
      workflowState: 'generated',
      progressId: '124'
    }, {
      date: '2017-01-03T15:55Z',
      link: 'http://example.com/stuff',
      workflowState: 'generated',
      progressId: '123'
    }]
    deepEqual(formatted, expected)
  })
})
