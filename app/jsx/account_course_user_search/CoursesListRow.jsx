define([
  'jquery',
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./UserLink",
  "compiled/views/courses/roster/CreateUsersView",
], function($, React, I18n, _, UserLink, CreateUsersView) {

  var { number, string, func, shape, arrayOf } = React.PropTypes;

  var CoursesListRow = React.createClass({
    propTypes: {
      id: string.isRequired,
      name: string.isRequired,
      workflow_state: string.isRequired,
      total_students: number.isRequired,
      teachers: arrayOf(shape(UserLink.propTypes)).isRequired
    },
    getInitialState () {
      let teachers = _.uniq(this.props.teachers, (t) => t.id);
      return {
        teachersToShow: _.compact([teachers[0], teachers[1]])
      };
    },
    showMoreLink () {
      if (this.props.teachers.length > 2 && this.state.teachersToShow.length === 2) {
        return <a className="showMoreLink" href="#" onClick={this.showMoreTeachers}> {I18n.t('Show More')}</a>
      } 
    },
    showMoreTeachers () {
      this.setState({teachersToShow: _.uniq(this.props.teachers, (t) => t.id)});
    },
    addUserToCourse () {
      let createUsersBackboneView = new CreateUsersView({title: I18n.t('Add People'), height: 520});
      createUsersBackboneView.open();
      createUsersBackboneView.on('close', () => {
        createUsersBackboneView.remove()
      });
    },
    render() {
      let { id, name, workflow_state, sis_course_id, total_students, teachers } = this.props;
      let url = `/courses/${id}`;
      let isPublished = workflow_state !== "unpublished";

      return (
        <div role='row' className="grid-row pad-box-mini border border-b">
          <div className="col-md-3">
            <div role='gridcell' className="grid-row">
              <div className="col-xs-2">{isPublished && (<i className="icon-publish courses-list__published-icon" />)}</div>
              <div className="col-xs-10">
                <div className="courseName">
                  <a href={url}>{name}</a>
                </div>
              </div>
            </div>
          </div>

          <div className="col-xs-1" role='gridcell'>
            <div className="courseSIS">{sis_course_id}</div>
          </div>

          <div className="col-md-3" role='gridcell'>
            {this.state.teachersToShow && this.state.teachersToShow.map((teacher) => <UserLink key={teacher.id} {...teacher} />)}
            { this.showMoreLink() }
          </div>

          <div className="col-md-3" role='gridcell'>
            <div className="totalStudents">{total_students}</div>
          </div>
          <div className="col-md-2" role='gridcell'>
            <div className="grid-row" style={{justifyContent: "flex-end"}}>
              <a className="al-trigger-gray icon-plus" href="#" onClick={this.addUserToCourse}></a>
              <a className="al-trigger-gray icon-stats" href={`/courses/${this.props.id}/statistics`}></a>
              <a className="al-trigger-gray icon-settings" href={`/courses/${this.props.id}/settings`}></a>
            </div>
          </div>
        </div>
      );
    }
  });

  return CoursesListRow;
});
