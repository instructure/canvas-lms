define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/webzip_export/components/Errors',
], (React, ReactDOM, enzyme, Errors) => {
  module('Web Zip Export Errors')

  test('renders the Error component', () => {
    const errors = [{response: 'Instance of demon found in code', code: 666}];
    const tree = enzyme.shallow(<Errors errors={errors} />)
    const node = tree.find('.webzipexport__errors')
    ok(node.exists())
  })
})
