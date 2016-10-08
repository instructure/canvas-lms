define([
  'react',
  'jsx/conditional_release_stats/components/breakdown-graph-bar',
], (React, BreakdownBarComponent) => {
  const TestUtils = React.addons.TestUtils

  module('Breakdown Stats Graph Bar')

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <BreakdownBarComponent {...props} />
    )
  }

  const defaultProps = () => {
    return {
      upperBound: '100',
      lowerBound: '70',
      rangeStudents: 50,
      totalStudents: 100,
      rangeIndex: 0,
      selectRange: () => {},
    }
  }

  test('renders bar component correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__container')
    equal(renderedList.length, 1, 'renders full component')
  })

  test('renders bar inner-components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-link-button')
    equal(renderedList.length, 1, 'renders full component')
  })

  test('renders bounds correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__info')
    equal(renderedList[0].textContent, '70+ to 100', 'renders full component')
  })

  test('renders students in range correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-link-button')
    equal(renderedList[0].textContent, '50 out of 100 students', 'renders correct amoutn of students')
  })
})
