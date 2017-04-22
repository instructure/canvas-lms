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
    existingAssociations: [],
    addedAssociations: [],
    removedAssociations: [],
    errors: [],
    addAssociations: () => {},
    removeAssociations: () => {},
    cancel: () => {},
    loadCourses: () => {},
    loadAssociations: () => {},
    saveAssociations: () => {},
    isLoadingCourses: false,
    isLoadingAssociations: false,
    isSavingAssociations: false,
    subAccounts: data.subAccounts,
    terms: data.terms,
  })

  test('renders the BlueprintSettings component', () => {
    const tree = enzyme.shallow(<BlueprintSettings {...defaultProps()} />)
    const node = tree.find('.bps__wrapper')
    ok(node.exists())
  })
})
