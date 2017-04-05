define([
  'react',
  'enzyme',
  'moxios',
  'jsx/webzip_export/App',
], (React, enzyme, moxios, WebZipExportApp) => {
  QUnit.module('WebZip Export App', {
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

  test('renders failed exports as well as generated exports', (assert) => {
    const done = assert.async()
    const data = [{
      created_at: '1776-12-25T22:00:00Z',
      zip_attachment: {url: null},
      workflow_state: 'failed',
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
      equal(node.length, 1)
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
      workflow_state: 'generating',
      progress_id: '123'
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

  test('render exports and progress bar if both exist', (assert) => {
    const done = assert.async()
    const data = [{
      created_at: '2017-01-03T15:55:00Z',
      zip_attachment: {url: 'http://example.com/stuff'},
      workflow_state: 'generating',
      progress_id: '124'
    },
    {
      created_at: '1776-12-25T22:00:00Z',
      zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
      workflow_state: 'generated',
      progress_id: '123'
    }]
    moxios.stubRequest('/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data
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
      created_at: '2017-01-03T15:55:00Z',
      zip_attachment: {url: 'http://example.com/stuff'},
      workflow_state: 'generating',
      progress_id: '124'
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

  test('renders different text for newly completed exports', (assert) => {
    const done = assert.async()
    const data = [{
      created_at: '2017-01-13T12:41:00Z',
      zip_attachment: {url: 'http://example.com/thing'},
      workflow_state: 'generated',
      progress_id: '126'
    }]
    moxios.stubRequest('/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data
    })
    ENV.context_asset_string = 'courses_2'
    const tree = enzyme.mount(<WebZipExportApp />)
    const app = tree.instance()
    const download = sinon.stub(app, 'downloadLink')
    app.getExports('126')
    moxios.wait(() => {
      const node = tree.find('ExportList')
      ok(node.text().startsWith('Most recent export: '))
      download.restore()
      done()
    })
  })

  test('should download a successful export', (assert) => {
    const done = assert.async()
    const data = [{
      created_at: '2017-01-13T12:41:00Z',
      zip_attachment: {url: 'http://example.com/thing'},
      workflow_state: 'generated',
      progress_id: '126'
    }]
    moxios.stubRequest('/api/v1/courses/2/web_zip_exports', {
      status: 200,
      responseText: data
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
    const data = [{
      created_at: '2017-01-03T15:55:00Z',
      zip_attachment: {url: 'http://example.com/stuff'},
      workflow_state: 'generated',
      progress_id: '123'
    },
    {
      created_at: '1776-12-25T22:00:00Z',
      zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
      workflow_state: 'generated',
      progress_id: '124'
    }]
    const formatted = WebZipExportApp.webZipFormat(data)
    const expected = [{
      date: '1776-12-25T22:00:00Z',
      link: 'http://example.com/washingtoncrossingdelaware',
      workflowState: 'generated',
      progressId: '124',
      newExport: false
    }, {
      date: '2017-01-03T15:55:00Z',
      link: 'http://example.com/stuff',
      workflowState: 'generated',
      progressId: '123',
      newExport: false
    }]
    deepEqual(formatted, expected)
  })

  test('marks new exports if given progress id', () => {
    const data = [{
      created_at: '2017-01-13T12:36:00Z',
      zip_attachment: {url: 'http://example.com/yo'},
      workflow_state: 'generated',
      progress_id: '125'
    }]
    const formatted = WebZipExportApp.webZipFormat(data, '125')
    const expected = [{
      date: '2017-01-13T12:36:00Z',
      link: 'http://example.com/yo',
      workflowState: 'generated',
      progressId: '125',
      newExport: true
    }]
    deepEqual(formatted, expected)
  })
})
