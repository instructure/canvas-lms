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

  module('datesAndLinksFromAPI')

  test('returns a JS object with webzip created_at dates and webzip export attachment urls', () => {
    const data = [{
      created_at: '2017-01-03T15:55Z',
      zip_attachment: {url: 'http://example.com/stuff'},
      workflow_state: 'generated',
    },
    {
      created_at: '1776-12-25T22:00Z',
      zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
      workflow_state: 'generated',
    }]
    const formatted = WebZipExportApp.datesAndLinksFromAPI(data)
    const expected = [{
      date: '1776-12-25T22:00Z',
      link: 'http://example.com/washingtoncrossingdelaware'
    },
    {
      date: '2017-01-03T15:55Z',
      link: 'http://example.com/stuff'
    }]
    deepEqual(formatted, expected)
  })

  test('does not include items with a workflow_state other than generated', () => {
    const data = [{
      created_at: '2017-01-03T15:55Z',
      zip_attachment: {url: 'http://example.com/stuff'},
      workflow_state: 'generating',
    },
    {
      created_at: '1776-12-25T22:00Z',
      zip_attachment: {url: 'http://example.com/washingtoncrossingdelaware'},
      workflow_state: 'generated',
    }]
    const formatted = WebZipExportApp.datesAndLinksFromAPI(data)
    const expected = [{
      date: '1776-12-25T22:00Z',
      link: 'http://example.com/washingtoncrossingdelaware'
    }]
    deepEqual(formatted, expected)
  })
})
