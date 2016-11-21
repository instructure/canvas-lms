define([
  'react',
  'classnames',
  'jsx/shared/helpers/assignment-categories',
  'jsx/shared/conditional_release/score',
  '../shapes/assignment',
], (React, classNames, categoryHelper, scoreHelpers, assignmentShape) => {
  const { object, number } = React.PropTypes

  return class StudentAssignmentItem extends React.Component {
    static propTypes = {
      assignment: assignmentShape.isRequired,
      trend: number,
      score: number,
    }

    render () {
      const { trend } = this.props

      const trendClasses = classNames({
        'crs-student__trend-icon': true,
        'crs-student__trend-icon__positive': trend === 1,
        'crs-student__trend-icon__neutral': trend === 0,
        'crs-student__trend-icon__negative': trend === -1,
      })

      const showTrend = trend !== null && trend !== undefined
      const category = categoryHelper.getCategory(this.props.assignment).id

      return (
        <div className='crs-student-details__assignment'>
          <i className={`icon-${category} crs-student-details__assignment-icon crs-icon-${category}`}></i>
          <div className='crs-student-details__assignment-name'>{this.props.assignment.name}</div>
          <div className='crs-student-details__assignment-score'>
            <div>{scoreHelpers.transformScore(this.props.assignment.score, this.props.assignment, true)}</div>
            {showTrend && (<span className={trendClasses}></span>)}
          </div>
        </div>
      )
    }
  }
})
