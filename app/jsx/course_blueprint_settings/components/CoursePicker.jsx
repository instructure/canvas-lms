define([
  'i18n!blueprint_config',
  'jquery',
  'react',
  'instructure-ui/ToggleDetails',
  'instructure-ui/Typography',
  'instructure-ui/Spinner',
  '../propTypes',
  './CourseFilter',
  './CoursePickerTable',
  'compiled/jquery.rails_flash_notifications',
], (I18n, $, React, {default: ToggleDetails}, {default: Typography}, {default: Spinner}, propTypes, CourseFilter, CoursePickerTable) => {
  const { func, bool, arrayOf, string } = React.PropTypes

  return class CoursePicker extends React.Component {
    static propTypes = {
      courses: propTypes.courseList.isRequired,
      excludeCourses: arrayOf(string),
      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
      loadCourses: func.isRequired,
      isLoadingCourses: bool.isRequired,
      onSelectedChanged: func,
      isExpanded: bool,
    }

    static defaultProps = {
      excludeCourses: [],
      onSelectedChanged: () => {},
      isExpanded: true,
    }

    constructor (props) {
      super(props)
      this.state = {
        isExpanded: props.isExpanded,
        announceChanges: false,
      }
    }

    componentWillReceiveProps (nextProps) {
      if (this.state.announceChanges && !this.props.isLoadingCourses && nextProps.isLoadingCourses) {
        $.screenReaderFlashMessage(I18n.t('Loading courses started'))
      }

      if (this.state.announceChanges && this.props.isLoadingCourses && !nextProps.isLoadingCourses) {
        this.setState({ announceChanges: false })
        $.screenReaderFlashMessage(I18n.t({
          one: 'Loading courses complete: one course found',
          other: 'Loading courses complete: %{count} courses found'
        }, { count: nextProps.courses.length }))
      }
    }

    reloadCourses () {
      this.props.loadCourses(this.state.filters)
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
        announceChanges: true,
      })
    }

    render () {
      const courses = this.props.courses.filter(course => !this.props.excludeCourses.includes(course.id))

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
                courses={courses}
                onSelectedChanged={this.onSelectedChanged}
              />
            </ToggleDetails>
          </div>
        </div>
      )
    }
  }
})
