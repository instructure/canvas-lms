define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/Heading',
  'instructure-ui/Typography',
  '../propTypes',
  './CoursePicker',
  './AssociationsTable',
], (I18n, React, {default: Heading}, {default: Typography}, propTypes, CoursePicker, AssociationsTable) => {
  const { func, bool } = React.PropTypes

  return class CourseAssociations extends React.Component {
    static propTypes = {
      courses: propTypes.courseList.isRequired,
      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
      loadCourses: func.isRequired,
      isLoadingCourses: bool.isRequired,
      isExpanded: bool,
    }

    static defaultProps = {
      isExpanded: false,
    }

    constructor (props) {
      super(props)
      this.state = {
        selected: {},
        availableCourses: this.props.courses,
        newAssociations: [],
      }
    }

    // when courses update bc of a new search
    // make sure to exclude courses we already selected
    componentWillReceiveProps (nextProps) {
      this.setState({
        availableCourses: this.findAvailableCourses(nextProps.courses, this.state.selected),
      })
    }

    selectCourses = (selected) => {
      const newSelected = Object.assign(this.state.selected, selected)
      this.setState({
        selected: newSelected,
        availableCourses: this.findAvailableCourses(this.props.courses, newSelected),
        newAssociations: this.state.newAssociations.concat(this.state.availableCourses.filter(course => newSelected[course.id])),
      })
    }

    removeAssociation = (courseId) => {
      const newSelected = Object.assign(this.state.selected, { [courseId]: false })
      this.setState({
        selected: newSelected,
        availableCourses: this.findAvailableCourses(this.props.courses, newSelected),
        newAssociations: this.state.newAssociations.filter(course => course.id !== courseId),
      })
    }

    findAvailableCourses (courses, selected) {
      return courses.filter(course => !selected[course.id])
    }

    render () {
      return (
        <div className="bps-course-associations">
          <CoursePicker
            courses={this.state.availableCourses}
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
            loadCourses={this.props.loadCourses}
            isLoadingCourses={this.props.isLoadingCourses}
            onSelectedChanged={this.selectCourses}
            isExpanded={this.props.isExpanded}
          />
          <hr />
          <Heading level="h3">{I18n.t('Associated')}</Heading>
          {this.state.newAssociations.length
           ? <AssociationsTable associations={this.state.newAssociations} onRemoveAssociation={this.removeAssociation} />
           : <Typography color="secondary" tag="p">{I18n.t('There are currently no associated courses.')}</Typography>}
        </div>
      )
    }
  }
})
