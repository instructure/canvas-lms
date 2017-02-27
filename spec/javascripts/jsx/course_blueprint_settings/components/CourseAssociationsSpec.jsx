define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/course_blueprint_settings/components/CourseAssociations',
  '../sampleData',
], (React, ReactDOM, enzyme, CourseAssociations, data) => {
  QUnit.module('CourseAssociations component')

  const defaultProps = () => ({
    courses: data.courses,
    subAccounts: data.subAccounts,
    terms: data.terms,
    isLoadingCourses: false,
    loadCourses: () => {},
  })

  test('renders the CourseAssociations component', () => {
    const tree = enzyme.shallow(<CourseAssociations {...defaultProps()} />)
    const node = tree.find('.bps-course-associations')
    ok(node.exists())
  })

  test('when course is checked, it is removed from picker and added to associations', () => {
    const props = defaultProps()
    props.isExpanded = true
    const tree = enzyme.mount(<CourseAssociations {...props} />)
    const checkbox = tree.find('CoursePickerTable .bps-table__course-row input[type="checkbox"]')
    checkbox.at(0).simulate('change', { target: { checked: true, value: '1' } })

    const rows = tree.find('.bps-associations__course-row')

    equal(rows.length, 1)
    equal(rows.at(0).find('td').at(0).text(), props.courses[0].name)
  })

  test('when course is removed from associations, it is added back to the picker', () => {
    const props = defaultProps()
    props.isExpanded = true
    const tree = enzyme.mount(<CourseAssociations {...props} />)
    const checkbox = tree.find('CoursePickerTable .bps-table__course-row input[type="checkbox"]')
    checkbox.at(0).simulate('change', { target: { checked: true, value: '1' } })

    let assocRows = tree.find('.bps-associations__course-row')
    assocRows.find('form').simulate('submit')

    assocRows = tree.find('.bps-associations__course-row')
    equal(assocRows.length, 0)

    const pickerRows = tree.find('CoursePickerTable .bps-table__course-row')
    equal(pickerRows.length, 2)
    equal(pickerRows.at(0).find('td').at(1).text(), props.courses[0].name)
  })
})
