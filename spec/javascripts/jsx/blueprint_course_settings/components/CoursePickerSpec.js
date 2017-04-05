import React from 'react'
import * as enzyme from 'enzyme'
import CoursePicker from 'jsx/blueprint_course_settings/components/CoursePicker'
import data from '../sampleData'

QUnit.module('CoursePicker component')

const defaultProps = () => ({
  courses: data.courses,
  subAccounts: data.subAccounts,
  terms: data.terms,
  isLoadingCourses: false,
  loadCourses: () => {},
  onSelectedChanged: () => {},
})

test('renders the CoursePicker component', () => {
  const tree = enzyme.shallow(<CoursePicker {...defaultProps()} />)
  const node = tree.find('.bca-course-picker')
  ok(node.exists())
})

test('displays spinner when loading courses', () => {
  const props = defaultProps()
  props.isLoadingCourses = true
  const tree = enzyme.shallow(<CoursePicker {...props} />)
  const node = tree.find('.bca-course-picker__loading')
  ok(node.exists())
})

test('calls loadCourses when filters are updated', () => {
  const props = defaultProps()
  props.loadCourses = sinon.spy()
  const tree = enzyme.mount(<CoursePicker {...props} />)
  const picker = tree.instance()

  picker.onFilterChange({
    term: '',
    subAccount: '',
    search: 'one',
  })

  ok(props.loadCourses.calledOnce)
})
