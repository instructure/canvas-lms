define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/course_blueprint_settings/components/BlueprintSettings',
  '../sampleData',
], (React, ReactDOM, enzyme, BlueprintSettings, data) => {
  QUnit.module('BlueprintSettings component')

  const defaultProps = () => ({
    courses: [],
    errors: [],
    loadCourses: () => {},
    isLoadingCourses: false,
    subAccounts: data.subAccounts,
    terms: data.terms,
  })

  test('renders the BlueprintSettings component', () => {
    const tree = enzyme.shallow(<BlueprintSettings {...defaultProps()} />)
    const node = tree.find('.bps__wrapper')
    ok(node.exists())
  })
})
