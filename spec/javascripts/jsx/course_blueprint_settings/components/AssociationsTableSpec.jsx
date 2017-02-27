define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/course_blueprint_settings/components/AssociationsTable',
  '../sampleData',
], (React, ReactDOM, enzyme, AssociationsTable, data) => {
  QUnit.module('AssociationsTable component')

  const defaultProps = () => ({
    associations: data.courses,
    onRemoveAssociation: () => {},
  })

  test('renders the AssociationsTable component', () => {
    const tree = enzyme.shallow(<AssociationsTable {...defaultProps()} />)
    const node = tree.find('.bps-associations-table')
    ok(node.exists())
  })

  test('displays correct table data', () => {
    const props = defaultProps()
    const tree = enzyme.mount(<AssociationsTable {...props} />)
    const rows = tree.find('.bps-associations__course-row')

    equal(rows.length, props.associations.length)
    equal(rows.at(0).find('td').at(0).text(), props.associations[0].name)
    equal(rows.at(1).find('td').at(0).text(), props.associations[1].name)
  })

  test('calls onRemoveAssociation when association remove button is clicked', () => {
    const props = defaultProps()
    props.onRemoveAssociation = sinon.spy()
    const tree = enzyme.mount(<AssociationsTable {...props} />)
    const button = tree.find('.bps-associations__course-row form')
    button.at(0).simulate('submit')

    equal(props.onRemoveAssociation.callCount, 1)
    equal(props.onRemoveAssociation.getCall(0).args[0], '1')
  })
})
