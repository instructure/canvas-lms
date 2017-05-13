import React from 'react'
import Spinner from 'instructure-ui/lib/components/Spinner'
import I18n from 'i18n!cyoe_assignment_sidebar'
import {transformScore} from 'jsx/shared/conditional_release/score'
import BarGraph from './breakdown-graph-bar'
  const { object, array, func, number, bool } = React.PropTypes

  class BreakdownGraphs extends React.Component {
    static propTypes = {
      assignment: object.isRequired,
      ranges: array.isRequired,
      enrolled: number.isRequired,
      isLoading: bool.isRequired,

      // actions
      openSidebar: func.isRequired,
      selectRange: func.isRequired,
    }

    renderContent () {
      if (this.props.isLoading) {
        return (
          <div className='crs-breakdown-graph__loading'>
            <Spinner title={I18n.t('Loading')} size='small' />
            <p>{I18n.t('Loading Data..')}</p>
          </div>
        )
      } else {
        return this.renderBars()
      }
    }

    renderBars () {
      const { ranges, assignment, enrolled, openSidebar, selectRange } = this.props
      return ranges.map(({ size, scoring_range }, i) => (
        <BarGraph
          key={i}
          rangeIndex={i}
          rangeStudents={size}
          totalStudents={enrolled}
          upperBound={transformScore(scoring_range.upper_bound, assignment, true)}
          lowerBound={transformScore(scoring_range.lower_bound, assignment, false)}
          openSidebar={openSidebar}
          selectRange={selectRange}
        />
      ))
    }

    render () {
      return (
        <div className='crs-breakdown-graph' >
          <h2>{I18n.t('Mastery Paths Breakdown')}</h2>
          {this.renderContent()}
        </div>
      )
    }
  }

export default BreakdownGraphs
