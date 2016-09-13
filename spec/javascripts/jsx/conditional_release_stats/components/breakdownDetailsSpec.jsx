define([
  'react',
  'react-dom',
  'jsx/conditional_release_stats/components/breakdown-details',
], (React, ReactDOM, BreakdownDetails) => {
  const container = document.getElementById('fixtures')

  module('Breakdown Details', {
    teardown() {
      ReactDOM.unmountComponentAtNode(container);
    }
  })

  // using ReactDOM instead of TestUtils to render because of InstUI
  const renderComponent = (props) => {
    return ReactDOM.render(
      <BreakdownDetails {...props} />
    , container)
  }

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
        size: 2,
        students: [
          {
            user: {
              id: 1,
              name: 'foo',
              login_id: 'student1',
            },
          },
          {
            user: {
              id: 2,
              name: 'bar',
              login_id: 'student2',
            },
          },
        ],
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
      submission_types: ['on_paper'],
      grading_scheme: null,
    },
    students: {
      '1': {
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
              submission_types: ['online_text_entry'],
            },
          },
        ],
      },
      '2': {
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
              submission_types: ['online_text_entry'],
            },
          },
        ],
      },
    },
    selectedPath: {
      range: 0,
      student: null,
    },
    isStudentDetailsLoading: false,

    // actions
    selectRange: () => {},
    selectStudent: () => {},
  })

  test('renders component correctly', () => {
    const component = renderComponent(defaultProps())

    const rendered = document.querySelectorAll('.crs-breakdown-details')
    equal(rendered.length, 1)
  })

  test('clicking next student calls select student with the next student index', () => {
    const props = defaultProps()
    props.selectedPath.student = 0
    props.selectStudent = sinon.spy()
    const component = renderComponent(props)

    const nextBtn = document.querySelector('.student-details__next-student')
    nextBtn.click()

    ok(props.selectStudent.calledWith(1))
  })

  test('clicking next student on the last student wraps around to first student', () => {
    const props = defaultProps()
    props.selectedPath.student = 1
    props.selectStudent = sinon.spy()
    const component = renderComponent(props)

    const nextBtn = document.querySelector('.student-details__next-student')
    nextBtn.click()

    ok(props.selectStudent.calledWith(0))
  })

  test('clicking prev student calls select student with the correct student index', () => {
    const props = defaultProps()
    props.selectedPath.student = 1
    props.selectStudent = sinon.spy()
    const component = renderComponent(props)

    const prevBtn = document.querySelector('.student-details__prev-student')
    prevBtn.click()

    ok(props.selectStudent.calledWith(0))
  })

  test('clicking prev student on first student wraps around to last student', () => {
    const props = defaultProps()
    props.selectedPath.student = 0
    props.selectStudent = sinon.spy()
    const component = renderComponent(props)

    const prevBtn = document.querySelector('.student-details__prev-student')
    prevBtn.click()

    ok(props.selectStudent.calledWith(1))
  })

  test('clicking back on student details unselects student', () => {
    const props = defaultProps()
    props.selectedPath.student = 0
    props.selectStudent = sinon.spy()
    const component = renderComponent(props)

    const backBtn = document.querySelector('.crs-back-button')
    backBtn.click()

    ok(props.selectStudent.calledWith(null))
  })
})
