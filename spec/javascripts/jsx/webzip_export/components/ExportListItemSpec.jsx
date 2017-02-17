define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/webzip_export/components/ExportListItem',
], (React, ReactDOM, enzyme, ExportListItem) => {
  QUnit.module('ExportListItem')

  test('renders the ExportListItem component', () => {
    const props = {
      date: 'Sept 11, 2001 at 8:46am',
      link: 'https://example.com/neverforget',
      workflowState: 'generated',
      newExport: false
    }
    const tree = enzyme.shallow(<ExportListItem {...props} />)
    const node = tree.find('.webzipexport__list__item')
    ok(node.exists())
  })

  test('renders different text for last success', () => {
    const props = {
      date: '2017-01-13T2:30:00Z',
      link: 'https://example.com/alwaysremember',
      workflowState: 'generated',
      newExport: true
    }
    const tree = enzyme.shallow(<ExportListItem {...props} />)
    const node = tree.find('.webzipexport__list__item')
    ok(node.text().startsWith('Most recent export'))
  })

  test('renders error text if last object failed', () => {
    const props = {
      date: '2017-01-13T2:30:00Z',
      link: 'https://example.com/alwaysremember',
      workflowState: 'failed',
      newExport: true
    }
    const tree = enzyme.shallow(<ExportListItem {...props} />)
    const node = tree.find('.text-error')
    ok(node.text().startsWith('Export failed'))
  })
})
