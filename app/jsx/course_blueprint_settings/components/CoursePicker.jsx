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
      onSelectedChanged: func,
      isExpanded: bool,
    }

    static defaultProps = {
      onSelectedChanged: () => {},
      isExpanded: true,
    }

    constructor (props) {
      super(props)
      this.state = {
        isExpanded: props.isExpanded,
      }
    }

    onSelectedChanged = (selected) => {
      this.props.onSelectedChanged(selected)
      this.setState({ isExpanded: true })
    }

    // when the filter updates, load new courses
    onFilterChange = (filters) => {
      this.props.loadCourses(filters)

      this.setState({
        filters,
        isExpanded: true,
      })
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
            <ToggleDetails isExpanded={this.state.isExpanded} summary={<Typography>{I18n.t('Courses')}</Typography>}>
              {this.props.isLoadingCourses && (<div className="bps-course-picker__loading">
                <Spinner title={I18n.t('Loading Courses')} />
              </div>)}
              <CoursePickerTable
                courses={this.props.courses}
                onSelectedChanged={this.onSelectedChanged}
              />
            </ToggleDetails>
          </div>
        </div>
      )
    }
  }
})
