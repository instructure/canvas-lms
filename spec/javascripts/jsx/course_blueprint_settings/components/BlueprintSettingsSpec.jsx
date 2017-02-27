define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/course_blueprint_settings/components/BlueprintSettings',
], (React, ReactDOM, enzyme, BlueprintSettings) => {
  QUnit.module('BlueprintSettings component')

  test('renders the BlueprintSettings component', () => {
    const tree = enzyme.shallow(<BlueprintSettings />)
    const node = tree.find('.bpc__wrapper')
    ok(node.exists())
  })
})
