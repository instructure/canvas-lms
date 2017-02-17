define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/ToggleDetails',
  'instructure-ui/Typography',
  'instructure-ui/Spinner',
  '../propTypes',
  './CourseFilter',
  './CoursePickerTable',
], (I18n, React, {default: ToggleDetails}, {default: Typography}, {default: Spinner}, propTypes, CourseFilter, CoursePickerTable) => {
  const { func, bool } = React.PropTypes

  return class CoursePicker extends React.Component {
    static propTypes = {
      courses: propTypes.courseList.isRequired,
      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
      loadCourses: func.isRequired,
      isLoadingCourses: bool.isRequired,
    }

    constructor (props = {}) {
      super(props)
      this.state = {
        isOpen: false,
      }
    }

    // when the filter updates, load new courses
    onFilterChange = (filters) => {
      this.props.loadCourses(filters)

      this.setState({
        filters,
        isOpen: true,
      })
    }

    toggleCourseSelect = (e) => {
      // TODO
    }

    render () {
      return (
        <div className="bps-course-picker">
          <CourseFilter
            ref={(c) => { this.filter = c }}
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
            onChange={this.onFilterChange}
          />
          <div className="bps-course-details__wrapper">
            <ToggleDetails isExpanded={this.state.isOpen} summary={<Typography>{I18n.t('Courses')}</Typography>}>
              {this.props.isLoadingCourses && (<div className="bps-course-picker__loading">
                <Spinner title={I18n.t('Loading Courses')} />
              </div>)}
              <CoursePickerTable
                courses={this.props.courses}
                onCourseSelect={this.toggleCourseSelect}
              />
            </ToggleDetails>
          </div>
        </div>
      )
    }
  }
})
