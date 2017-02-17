define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/course_blueprint_settings/components/CoursePickerTable',
  '../sampleData',
], (React, ReactDOM, enzyme, CoursePickerTable, data) => {
  QUnit.module('CoursePickerTable component')

  const defaultProps = () => ({
    courses: data.courses,
    onCourseSelect: () => {},
  })

  test('renders the CoursePickerTable component', () => {
    const tree = enzyme.shallow(<CoursePickerTable {...defaultProps()} />)
    const node = tree.find('.bps-table__wrapper')
    ok(node.exists())
  })

  test('show no results if no courses passed in', () => {
    const props = defaultProps()
    props.courses = []
    const tree = enzyme.shallow(<CoursePickerTable {...props} />)
    const node = tree.find('.bps-table__no-results')
    ok(node.exists())
  })

  test('displays correct table data', () => {
    const props = defaultProps()
    const tree = enzyme.mount(<CoursePickerTable {...props} />)
    const rows = tree.find('.bps-table__course-row')

    equal(rows.length, props.courses.length)
    equal(rows.at(0).find('td').at(1).text(), props.courses[0].name)
    equal(rows.at(1).find('td').at(1).text(), props.courses[1].name)
  })
})
