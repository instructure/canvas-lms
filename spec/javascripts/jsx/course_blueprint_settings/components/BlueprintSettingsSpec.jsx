define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/course_blueprint_settings/components/BlueprintSettings',
], (React, ReactDOM, enzyme, BlueprintSettings) => {
  QUnit.module('BlueprintSettings component')

  const defaultProps = () => ({
    course: { id: '1', name: 'Course One' },
    terms: [
      { id: '1', name: 'Term One' },
      { id: '2', name: 'Term Two' },
    ],
    subAccounts: [
      { id: '1', name: 'Account One' },
      { id: '2', name: 'Account Two' },
    ],
  })

  test('renders the BlueprintSettings component', () => {
    const tree = enzyme.shallow(<BlueprintSettings {...defaultProps()} />)
    const node = tree.find('.bps__wrapper')
    ok(node.exists())
  })
})
