define([
  'react',
  'react-dom',
  'jsx/conditional_release_stats/components/student-ranges-view',
], (React, ReactDOM, RangesView) => {
  const container = document.getElementById('fixtures')

  module('Student Ranges View', {
    teardown() {
      ReactDOM.unmountComponentAtNode(container)
    }
  })

  const defaultProps = () => ({
    ranges: [
      {
        scoring_range: {
          id: 1,
          rule_id: 1,
          lower_bound: 0.7,
          upper_bound: 1.0,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 0,
        students: [],
      },
      {
        scoring_range: {
          id: 3,
          rule_id: 1,
          lower_bound: 0.4,
          upper_bound: 0.7,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 0,
        students: [],
      },
      {
        scoring_range: {
          id: 2,
          rule_id: 1,
          lower_bound: 0.0,
          upper_bound: 0.4,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 0,
        students: [],
      },
    ],
    assignment: {
      id: 7,
      title: 'Points',
      description: '',
      points_possible: 15,
      grading_type: 'points',
      submission_types: 'on_paper',
      grading_scheme: null,
    },
    selectedPath: {
      range: 0,
      student: null,
    },
    loadStudent: () => {},
    selectRange: () => {},
    selectStudent: () => {},
  })

  // using ReactDOM instead of TestUtils to render because of InstUI
  const renderComponent = (props) => {
    return ReactDOM.render(
      <RangesView {...props} />
    , container)
  }

  test('renders three ranges components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = document.querySelectorAll('.crs-student-range')
    equal(renderedList.length, 3, 'renders full component')
  })
})
