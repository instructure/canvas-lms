define([
  'react',
  'jsx/cyoe_assignment_sidebar/components/conditional-breakdown-bar',
], (React, BreakdownBarComponent) => {

  const TestUtils = React.addons.TestUtils;

  module('Breakdown Stats Bar');

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(<BreakdownBarComponent
      {...props}
    />);
  }

  const defaultProps = () => {
    return {
      upperBound: '100',
      lowerBound: '70',
      studentsPerRangeCount: 50,
      totalStudentsEnrolled: 100,
      path:'',
      isTop: false,
      isBottom: false,
    }
  }

  test('renders bar component correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__container')
    deepEqual(renderedList.length, 1, 'renders full component');

  });

  test('renders bar inner-components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__link')
    deepEqual(renderedList.length, 1, 'renders full component');

  });

  test('renders bounds correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__info')
    deepEqual(renderedList[0].textContent, '70+ to 100', 'renders full component');

  });

  test('renders students in range correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__link')
    deepEqual(renderedList[0].textContent, '50 out of 100 students', 'renders correct amoutn of students');
  });

});
