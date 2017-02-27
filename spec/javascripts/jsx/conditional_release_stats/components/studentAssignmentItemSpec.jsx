define([
  'react',
  'react-addons-test-utils',
  'jsx/conditional_release_stats/components/student-assignment-item',
], (React, TestUtils, AssignmentItem) => {

  QUnit.module('Student Assignment Item')

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <AssignmentItem {...props} />
    )
  }

  const defaultProps = () => {
    return {
      assignment: {
        name: 'hello world',
        grading_type: 'percent',
        points_possible: 100,
        submission_types: [
          'online_text_entry',
        ],
      },
      trend: 0,
      score: 0.8,
    }
  }

  test('renders assignment item correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__assignment')
    equal(renderedList.length, 1, 'does not render crs-student-details__assignment')
  })

  test('renders bar inner-components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__assignment-icon')
    equal(renderedList.length, 1, 'does not render student details assignment icon')
  })

  test('renders name correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__assignment-name')
    equal(renderedList[0].textContent, 'hello world', 'does not render student details assignment name')
  })

  test('renders trend icon', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon')
    equal(renderedList.length, 1, 'does not render trend icon')
  })

  test('renders correct icon type', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'icon-assignment')
    equal(renderedList.length, 1, 'does not render correct assignment icon type')
  })

  test('renders no trend correctly', () => {
    const props = defaultProps()
    props.trend = null
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon')
    equal(renderedList.length, 0)
  })

  test('renders positive trend correctly', () => {
    const props = defaultProps()
    props.trend = 1
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon__positive')
    equal(renderedList.length, 1, 'does not render positive trend icon')
  })

  test('renders neutral trend correctly', () => {
    const props = defaultProps()
    props.trend = 0
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon__neutral')
    equal(renderedList.length, 1, 'does not render neutral trend icon')
  })

  test('renders negative trend correctly', () => {
    const props = defaultProps()
    props.trend = -1
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student__trend-icon__negative')
    equal(renderedList.length, 1, 'does not render negative trend icon')
  })
})
