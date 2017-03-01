define([
  'i18n!blueprint_config',
  'react',
  '../propTypes',
  './CourseFilter',
], (I18n, React, propTypes, CourseFilter) => {
  return class CoursePicker extends React.Component {
    static propTypes = {
      courses: propTypes.courseList,
      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
    }

    static defaultProps = {
      courses: [],
    }

    render () {
      return (
        <div className="bps-course-picker">
          <CourseFilter
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
          />
        </div>
      )
    }
  }
})
