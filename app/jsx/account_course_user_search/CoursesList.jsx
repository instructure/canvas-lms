define([
  'react',
  'jquery',
  'i18n!account_course_user_search',
  'compiled/util/natcompare',
  'axios',
  './CoursesListRow',
], (React, $, I18n, natcompare, axios, CoursesListRow) => {
  const { string, shape, arrayOf } = React.PropTypes

  return class CoursesList extends React.Component {
    static propTypes = {
      courses: arrayOf(shape(CoursesListRow.propTypes)).isRequired,
      addUserUrls: shape({
        USER_LISTS_URL: string.isRequired,
        ENROLL_USERS_URL: string.isRequired,
      }).isRequired,
      roles: arrayOf(shape({ id: string.isRequired })).isRequired,
    }

    constructor () {
      super()
      this.state = {
        sections: [],
      }
    }

    componentWillMount () {
      this.props.courses.forEach((course) => {
        axios
          .get(`/api/v1/courses/${course.id}/sections`)
          .then((response) => {
            this.setState({
              sections: this.state.sections.concat(response.data)
            })
          })
      })
    }

    render () {
      const courses = this.props.courses

      return (
        <div className="content-box" role="grid">
          <div role="row" className="grid-row border border-b pad-box-mini">
            <div className="col-xs-5">
              <div className="grid-row">
                <div className="col-xs-2" />
                <div className="col-xs-10" role="columnheader">
                  <span className="courses-user-list-header">
                    {I18n.t('Course')}
                  </span>
                </div>
              </div>
            </div>
            <div role="columnheader" className="col-xs-1">
              <span className="courses-user-list-header">
                {I18n.t('SIS ID')}
              </span>
            </div>
            <div role="columnheader" className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t('Teacher')}
              </span>
            </div>
            <div role="columnheader" className="col-xs-1">
              <span className="courses-user-list-header">
                {I18n.t('Enrollments')}
              </span>
            </div>
            <div role="columnheader" className="col-xs-2">
              <span className="screenreader-only">{I18n.t('Course option links')}</span>
            </div>
          </div>

          <div className="courses-list" role="rowgroup">
            {courses.sort(natcompare.byKey('name')).map((course) => {
              const urlsForCourse = {
                USER_LISTS_URL: $.replaceTags(this.props.addUserUrls.USER_LISTS_URL, 'id', course.id),
                ENROLL_USERS_URL: $.replaceTags(this.props.addUserUrls.ENROLL_USERS_URL, 'id', course.id)
              }

              const courseSections = this.state.sections.filter(section => section.course_id === parseInt(course.id, 10))

              return (
                <CoursesListRow
                  key={course.id}
                  courseModel={courses}
                  roles={this.props.roles}
                  urls={urlsForCourse}
                  sections={courseSections}
                  {...course}
                />
              )
            })}
          </div>
        </div>
      )
    }
  }
})
