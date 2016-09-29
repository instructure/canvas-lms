define([
  'react',
  'react-dom',
  'helpers/fakeENV',
  'jsx/conditional_release_stats/index',
  'jsx/conditional_release_stats/components/breakdown-graphs'
], (React, ReactDOM, fakeENV, CyoeStats, BreakdownGraphs) => {
  const TestUtils = React.addons.TestUtils

  const defaultEnv = () => ({
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
    enrolled: 10,
    assignment: {
      id: 7,
      title: 'Points',
      description: '',
      points_possible: 15,
      grading_type: 'points',
      submission_types: 'on_paper',
      grading_scheme: null,
    },
    isLoading: false,
    selectRange: () => {},
  })

  let testNode = null

  module('CyoeStats - init', {
    setup() {
      fakeENV.setup();
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = defaultEnv()
      ENV.current_user_roles = ['teacher']
      ENV.CONDITIONAL_RELEASE_ENV.rule = {}

      testNode = document.createElement('div')
      document.getElementById('fixtures').appendChild(testNode)
  },

    teardown() {
      fakeENV.teardown();
      document.getElementById('fixtures').removeChild(testNode)
      testNode = null
    }
  })

  class IndexSpecContainer extends React.Component {
    render() {
      return (
        <div>
          <div className='test-details' />
          <div className='test-graphs' />
        </div>
      )
    }
  }

  const prepDocument = () => {
    return ReactDOM.render(<IndexSpecContainer />, testNode)
  }

  const testRender = (expectedToRender) => {
    const doc = prepDocument()
    const graphsRoot = TestUtils.findRenderedDOMComponentWithClass(doc, 'test-graphs')
    const detailsParent = TestUtils.findRenderedDOMComponentWithClass(doc, 'test-details')
    CyoeStats.init(graphsRoot, detailsParent)

    const childCount = expectedToRender ? 1 : 0
    const renderedGraphs = graphsRoot.getElementsByClassName('crs-breakdown-graph')
    const renderedDetails = detailsParent.getElementsByClassName('crs-breakdown-details')
    equal(renderedGraphs.length, childCount)
    equal(renderedDetails.length, childCount)
  }

  test('adds the react components in the correct places', () => {
    testRender(true)
  })

  test('does not add components when mastery paths not enabled', () => {
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    testRender(false)
  })

  test('does not add for a non-teacher', () => {
    ENV.current_user_roles = []
    testRender(false)
  })

  test('does not add if there is not a rule defined', () => {
    ENV.CONDITIONAL_RELEASE_ENV.rule = null
    testRender(false)
  })
})
