import React from 'react'
import * as enzyme from 'enzyme'
import AssociationsTable from 'jsx/blueprint_course_settings/components/AssociationsTable'
import data from '../sampleData'

QUnit.module('AssociationsTable component')

const defaultProps = () => ({
  existingAssociations: data.courses,
  addedAssociations: [],
  removedAssociations: [],
  onRemoveAssociations: () => {},
  isLoadingAssociations: false,
})

test('renders the AssociationsTable component', () => {
  const tree = enzyme.shallow(<AssociationsTable {...defaultProps()} />)
  const node = tree.find('.bca-associations-table')
  ok(node.exists())
})

test('displays correct table data', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<AssociationsTable {...props} />)
  const rows = tree.find('.bca-associations__course-row')

  equal(rows.length, props.existingAssociations.length)
  equal(rows.at(0).find('td').at(0).text(), props.existingAssociations[0].name)
  equal(rows.at(1).find('td').at(0).text(), props.existingAssociations[1].name)
})

test('calls onRemoveAssociations when association remove button is clicked', () => {
  const props = defaultProps()
  props.onRemoveAssociations = sinon.spy()
  const tree = enzyme.mount(<AssociationsTable {...props} />)
  const button = tree.find('.bca-associations__course-row form')
  button.at(0).simulate('submit')

  equal(props.onRemoveAssociations.callCount, 1)
  deepEqual(props.onRemoveAssociations.getCall(0).args[0], ['1'])
})
