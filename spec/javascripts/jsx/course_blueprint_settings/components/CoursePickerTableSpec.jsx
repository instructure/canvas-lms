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
    onSelectedChanged: () => {},
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

  test('calls onSelectedChanged when courses are selected', () => {
    const props = defaultProps()
    props.onSelectedChanged = sinon.spy()
    const tree = enzyme.mount(<CoursePickerTable {...props} />)
    const checkbox = tree.find('.bps-table__course-row input[type="checkbox"]')
    checkbox.at(0).simulate('change', { target: { checked: true, value: '1' } })

    equal(props.onSelectedChanged.callCount, 1)
    deepEqual(props.onSelectedChanged.getCall(0).args[0], { 1: true })
  })

  test('calls onSelectedChanged when courses are unselected', () => {
    const props = defaultProps()
    props.onSelectedChanged = sinon.spy()
    const tree = enzyme.mount(<CoursePickerTable {...props} />)
    const checkbox = tree.find('.bps-table__course-row input[type="checkbox"]')
    checkbox.at(0).simulate('change', { target: { checked: true, value: '1' } })
    checkbox.at(0).simulate('change', { target: { checked: false, value: '1' } })

    equal(props.onSelectedChanged.callCount, 2)
    deepEqual(props.onSelectedChanged.getCall(0).args[0], { 1: false })
  })

  test('calls onSelectedChanged with correct data when "Select All" is selected', () => {
    const props = defaultProps()
    props.onSelectedChanged = sinon.spy()
    const tree = enzyme.mount(<CoursePickerTable {...props} />)

    const checkbox = tree.find('.btps-table__header-wrapper input[type="checkbox"]')
    checkbox.at(0).simulate('change', { target: { checked: true, value: 'all' } })

    equal(props.onSelectedChanged.callCount, 1)
    deepEqual(props.onSelectedChanged.getCall(0).args[0], { 1: true, 2: true })
  })
})
