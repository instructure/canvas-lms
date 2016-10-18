define([
  'react',
  'react-addons-test-utils',
  'jsx/conditional_release_stats/components/student-details-view',
], (React, TestUtils, StudentDetailsComponent) => {

  module('Student Details View Component')

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <StudentDetailsComponent {...props} />
    )
  }

  const defaultProps = () => {
    return {
      isLoading: false,
      student: {
        id: 3,
        name: 'foo',
        sortable_name: 'student@instructure.com',
        short_name: 'student@instructure.com',
        login_id: 'student',
      },
      triggerAssignment: {
        assignment: {
          id: '1',
          name: 'hello world',
          points_possible: 100,
          grading_type: 'percent',
        },
        submission: {
          submitted_at: '2016-08-22T14:52:43Z',
          grade: '100',
        },
      },
      followOnAssignments: [
        {
          score: 100,
          trend: 1,
          assignment: {
            id: '2',
            name: 'hello world',
            grading_type: 'percent',
            points_possible: 100,
            submission_types: [
              'online_text_entry',
            ],
          },
        },
      ],

      selectNextStudent: () => {},
      selectPrevStudent: () => {},
      unselectStudent: () => {},
    }
  }

  test('renders full view component correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details')
    equal(renderedList.length, 1, 'renders full component')
  })

  test('renders header correctly', () => {
    const component = renderComponent(defaultProps())

    const headerList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__header')
    equal(headerList.length, 1, 'renders header component')
  })

  test('renders profile section correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__profile-content')
    equal(renderedList.length, 1, 'renders the profile section')
  })

  test('renders content section correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__score-content')
    equal(renderedList.length, 1, 'renders all assignment content')
  })

  test('renders correct student name', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__name')
    equal(renderedList[0].textContent, 'foo', 'renders the name of student')
  })

  test('renders correct assignment name', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__score-title')
    equal(renderedList[0].textContent, 'hello world', 'renders the correct assignment score')
  })

  test('renders correct submit date', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-details__score-date')
    equal(renderedList[0].textContent, 'Submitted: August 22, 2016', 'renders the correct assignment date')
  })

  test('renders links correctly', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-breakdown__link')
    equal(renderedList.length, 3, 'renders three content links')
  })

})
