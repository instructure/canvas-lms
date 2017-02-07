define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/webzip_export/components/ExportListItem',
], (React, ReactDOM, TestUtils, ExportListItem) => {
  module('ExportListItem')

  test('renders the ExportListItem component', () => {
    const date = 'Sept 11, 2001 @ 8:46 AM'
    const link = 'https://example.com/neverforget'

    const tree = TestUtils.renderIntoDocument(<ExportListItem date={date} link={link} />)
    const ExportListItemComponent = TestUtils.scryRenderedDOMComponentsWithClass(tree, 'webzipexport__list__item')[0]
    ok(ExportListItemComponent)
  })
})
