define([
  'react',
  'classnames',
  './student-ranges-view',
  './student-details-view',
], (React, classNames, StudentRangeView, StudentDetailsView) => {
  const { array, object, func } = React.PropTypes

  return class BreakdownDetails extends React.Component {
    static get propTypes () {
      return {
        ranges: array.isRequired,
        assignment: object.isRequired,
        selectedPath: object.isRequired,

        // actions
        selectRange: func.isRequired,
        selectStudent: func.isRequired,
      }
    }

    render () {
      const contentClasses = classNames({
        'crs-breakdown-details__content': true,
        'crs-breakdown-details__content__shifted': !!this.props.selectedPath.student,
      })

      return (
        <div className='crs-breakdown-details'>
          <div className={contentClasses}>
            <StudentRangeView
              assignment={this.props.assignment}
              ranges={this.props.ranges}
              selectedPath={this.props.selectedPath}
              selectRange={this.props.selectRange}
              selectStudent={this.props.selectStudent}
            />
          </div>
        </div>
      )
    }
  }
})
