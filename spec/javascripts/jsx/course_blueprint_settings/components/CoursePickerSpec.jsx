define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/course_blueprint_settings/components/CoursePicker',
  '../sampleData',
], (React, ReactDOM, enzyme, CoursePicker, data) => {
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
    const node = tree.find('.bps-course-picker')
    ok(node.exists())
  })

  test('displays spinner when loading courses', () => {
    const props = defaultProps()
    props.isLoadingCourses = true
    const tree = enzyme.shallow(<CoursePicker {...props} />)
    const node = tree.find('.bps-course-picker__loading')
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
})
