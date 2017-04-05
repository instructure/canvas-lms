import React from 'react'
import * as enzyme from 'enzyme'
import BlueprintAssociations from 'jsx/blueprint_course_settings/components/BlueprintAssociations'
import data from '../sampleData'

QUnit.module('BlueprintAssociations component')

const defaultProps = () => ({
  courses: [],
  existingAssociations: [],
  addedAssociations: [],
  removedAssociations: [],
  errors: [],
  addAssociations: () => {},
  removeAssociations: () => {},
  loadCourses: () => {},
  loadAssociations: () => {},
  isLoadingCourses: false,
  isLoadingAssociations: false,
  isSavingAssociations: false,
  subAccounts: data.subAccounts,
  terms: data.terms,
})

test('renders the BlueprintSettings component', () => {
  const tree = enzyme.shallow(<BlueprintAssociations {...defaultProps()} />)
  const node = tree.find('.bca__wrapper')
  ok(node.exists())
})
