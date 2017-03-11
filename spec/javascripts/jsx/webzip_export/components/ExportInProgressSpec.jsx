define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/webzip_export/components/ExportInProgress',
], (React, ReactDOM, enzyme, ExportInProgress) => {
  QUnit.module('ExportInProgress')

  test('renders the ExportInProgress component', () => {
    const webzip = {progressId: '117'}
    const tree = enzyme.shallow(<ExportInProgress webzip={webzip} loadExports={() => {}} />)

    const node = tree.find('.webzipexport__inprogress')

    ok(node.exists())
  })

  test('doesnt render when completed is true', () => {
    const webzip = {progressId: '117'}
    const tree = enzyme.shallow(<ExportInProgress webzip={webzip} loadExports={() => {}} />)

    tree.setState({completed: true})

    const node = tree.find('.webzipexport__inprogress')

    equal(node.length, 0)
  })
})
