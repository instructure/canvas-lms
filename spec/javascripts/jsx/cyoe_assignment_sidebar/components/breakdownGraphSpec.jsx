define([
  'react',
  'jsx/cyoe_assignment_sidebar/components/conditional-stats-component',
], (React, BreakdownGraphComponent) => {

  const TestUtils = React.addons.TestUtils;

  module('Breakdown Graph Tests');

  const defaultState = {
    ranges : [
      {
         scoring_range:{
            id:1,
            rule_id:1,
            lower_bound:0.7,
            upper_bound:1.0,
            created_at: null,
            updated_at: null,
            position:null
         },
         size:0,
         students:[]
      },
      {
         scoring_range:{
            id:3,
            rule_id:1,
            lower_bound:0.4,
            upper_bound:0.7,
            created_at: null,
            updated_at: null,
            position:null
         },
         size:0,
         students:[]
      },
      {
         scoring_range:{
            id:2,
            rule_id:1,
            lower_bound:0.0,
            upper_bound:0.4,
            created_at: null,
            updated_at: null,
            position:null
         },
         size:0,
         students:[]
      }
    ],
    enrolled : 10,
    assignment : {
      id: 7,
      title: 'Points',
      description: '',
      points_possible: 15,
      grading_type: 'points',
      submission_types: 'on_paper',
      grading_scheme: null
    },
    global_shared : {
      errors : [],
      open : null
    }
  };

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(<BreakdownGraphComponent
      {...props}
    />);
  }

  const defaultProps = () => {
    return {
      state: defaultState
    }
  }

  test('renders three bar components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__container')
    deepEqual(renderedList.length, 3, 'renders full component');
  });

  test('renders bar inner-components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__link')
    deepEqual(renderedList.length, 3, 'renders links to sidebar');
  });

  test('renders lower bound correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__info')
    deepEqual(renderedList[2].textContent, "0 pts+ to 6 pts", 'renders bottom scores');
  });

  test('renders upper bound correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__info')
    deepEqual(renderedList[0].textContent, '11 pts+ to 15 pts', 'renders upper scores');
  });


  test('renders enrolled correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__link')
    deepEqual(renderedList[0].textContent, '0 out of 10 students', 'renders upper scores');
  });

});
