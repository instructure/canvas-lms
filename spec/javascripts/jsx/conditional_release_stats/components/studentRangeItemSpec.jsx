define([
  'react',
  'jsx/conditional_release_stats/components/student-range-item',
], (React, StudentRangeItem) => {
  const TestUtils = React.addons.TestUtils

  module('Student Range Item')

  const defaultProps = () => ({
    studentIndex: 0,
    student: {
      user: { name: 'Foo Bar' },
      progress: 0,
    },
    onSelect: () => {},
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

  test('renders positive progress correctly', () => {
    const props = defaultProps()
    props.student.progress = 1
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__progress-icon__positive')
    equal(renderedList.length, 1, 'renders component')
  })

  test('renders neutral progress correctly', () => {
    const props = defaultProps()
    props.student.progress = 0
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__progress-icon__neutral')
    equal(renderedList.length, 1, 'renders component')
  })

  test('renders negative progress correctly', () => {
    const props = defaultProps()
    props.student.progress = -1
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__progress-icon__negative')
    equal(renderedList.length, 1, 'renders component')
  })
})
