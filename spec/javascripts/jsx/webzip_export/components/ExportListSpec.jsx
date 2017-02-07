define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/webzip_export/components/ExportList',
], (React, ReactDOM, enzyme, ExportList) => {
  module('ExportList')

  test('renders the ExportList component', () => {
    const exports = [{
      date: 'July 4, 1776 at 3:33pm',
      link: 'https://example.com/declarationofindependence',
      workflowState: 'generated',
      newExport: false
    }, {
      date: 'Nov 9, 1989 at 9am',
      link: 'https://example.com/berlinwallfalls',
      workflowState: 'generated',
      newExport: false
    }]

    const tree = enzyme.shallow(<ExportList exports={exports} />)
    const node = tree.find('.webzipexport__list')
    ok(node.exists())
  })

  test('renders empty text if there are no exports', () => {
    const exports = []
    const tree = enzyme.shallow(<ExportList exports={exports} />)
    const node = tree.find('.webzipexport__list')
    equal(node.text(), 'No exports to display')
  })
})
