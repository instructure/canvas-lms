define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/webzip_export/components/ExportList',
], (React, ReactDOM, TestUtils, ExportList) => {
  module('ExportList')

  test('renders the ExportList component', () => {
    const exports = [
      {date: 'July 4, 1776 @ 3:33 PM', link: 'https://example.com/declarationofindependence'},
      {date: 'Nov 9, 1989 @ 9:00 AM', link: 'https://example.com/berlinwallfalls'}
    ]

    const tree = TestUtils.renderIntoDocument(<ExportList exports={exports} />)
    const ExportListComponent = TestUtils.findRenderedDOMComponentWithClass(tree, 'webzipexport__list')
    ok(ExportListComponent)
  })
})
