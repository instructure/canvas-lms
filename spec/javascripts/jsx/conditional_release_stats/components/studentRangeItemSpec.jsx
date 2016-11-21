define([
  'react',
  'react-addons-test-utils',
  'jsx/conditional_release_stats/components/student-range-item',
], (React, TestUtils, StudentRangeItem) => {

  module('Student Range Item')

  const defaultProps = () => ({
    studentIndex: 0,
    student: {
      user: { name: 'Foo Bar' },
      trend: 0,
    },
    selectStudent: () => {},
  })

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <StudentRangeItem {...props} />
    )
  }

  test('renders name correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.findRenderedDOMComponentWithClass(component, 'crs-student__name')
    equal(renderedList.textContent, 'Foo Bar', 'renders student name')
  })

  test('renders no trend correctly', () => {
    const props = defaultProps()
    props.student.trend = null
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon')
    equal(renderedList.length, 0, 'renders component')
  })

  test('renders positive trend correctly', () => {
    const props = defaultProps()
    props.student.trend = 1
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon__positive')
    equal(renderedList.length, 1, 'renders component')
  })

  test('renders neutral trend correctly', () => {
    const props = defaultProps()
    props.student.trend = 0
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon__neutral')
    equal(renderedList.length, 1, 'renders component')
  })

  test('renders negative trend correctly', () => {
    const props = defaultProps()
    props.student.trend = -1
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon__negative')
    equal(renderedList.length, 1, 'renders component')
  })
})
