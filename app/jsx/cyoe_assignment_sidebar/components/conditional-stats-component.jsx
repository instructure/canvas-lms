define([
  'react',
  '../components/conditional-breakdown-bar',
  '../score-helpers',
  'i18n!cyoe_assignment_sidebar'
], function(React, BarComponent, scoreHelpers, I18n) {

  const { object } = React.PropTypes;

  class ConditionalBreakdownGraph extends React.Component {
    static get propTypes () {
      return {
        state: object,
      }
    }

    render() {
      return (
        <div className='crs-breakdown-graph' >
          <p className='crs-breakdown-title'>{I18n.t('Mastery Paths Breakdown')}</p>
            {this.renderApp(this.props.state)}
        </div>
    )}

    renderApp(state){
      if (state.ranges) {
        return this.renderBarsApp(state)
      }
      else {
        return this.renderLoadingScreen()
      }
    }

    renderLoadingScreen() {
      return (
        <div>
          <p>{I18n.t('Loading Mastery Paths...')}</p>
        </div>
    )}

    renderBarsApp (state) {
      return state.ranges.map((bucket, i) => {
        return (
          <BarComponent
            key={i}
            upperBound={scoreHelpers.transformScore(bucket.scoring_range.upper_bound, state.assignment, true)}
            lowerBound={scoreHelpers.transformScore(bucket.scoring_range.lower_bound, state.assignment, false)}
            studentsPerRangeCount={bucket.size}
            totalStudentsEnrolled={state.enrolled}
            path=''
            isTop={i === 0}
            isBottom={i === state.ranges.length - 1}
          />
        )
      })
    }
  }

  return ConditionalBreakdownGraph;

});
