define([
  'jquery',
  "react",
  "Backbone",
  "i18n!account_course_user_search",
  "underscore",
  "./UserLink",
  "compiled/views/courses/roster/CreateUsersView",
  "compiled/collections/RosterUserCollection",
  "compiled/collections/SectionCollection",
  "compiled/collections/RolesCollection",
  "compiled/models/Role",
  "compiled/models/CreateUserList",
], function($, React, {Model}, I18n, _, UserLink, CreateUsersView, RosterUserCollection, SectionCollection, RolesCollection, Role, CreateUserList) {

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
      const course = new Model({id: this.props.id});

      const userCollection = new RosterUserCollection(null, {
        course_id: this.props.id,
        sections: new SectionCollection(this.props.sections),
        params: {
          include: ['avatar_url', 'enrollments', 'email', 'observed_users', 'can_be_removed'],
          per_page: 50
        }
      });

      userCollection.fetch();
      userCollection.once('reset', () => {
        userCollection.on('reset', () => {
          const numUsers = userCollection.length;
          let msg = "";
          if (numUsers === 0) {
            msg = I18n.t("No matching users found.");
          }
          else if (numUsers === 1) {
            msg = I18n.t("1 user found.");
          }
          else {
            msg = I18n.t("%{userCount} users found.", {userCount: numUsers});
          }
          $('#aria_alerts').empty().text(msg);
        });
      });

      const createUsersViewParams = {
        collection: userCollection,
        rolesCollection: new RolesCollection(this.props.roles.map((role) => new Role(role))),
        model: new CreateUserList({
          sections: this.props.sections,
          roles: this.props.roles,
          readURL: this.props.urls.USER_LISTS_URL,
          updateURL: this.props.urls.ENROLL_USERS_URL
        }),
        courseModel: course,
        title: I18n.t('Add People'),
        height: 520,
        className: 'form-dialog'

      };

      let createUsersBackboneView = new CreateUsersView(createUsersViewParams);
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
          <div className="col-xs-5">
            <div role='gridcell' className="grid-row middle-xs">
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

          <div className="col-xs-3" role='gridcell'>
            {this.state.teachersToShow && this.state.teachersToShow.map((teacher) => <UserLink key={teacher.id} {...teacher} />)}
            { this.showMoreLink() }
          </div>

          <div className="col-xs-1" role='gridcell'>
            <div className="totalStudents">{I18n.n(total_students)}</div>
          </div>
          <div className="col-xs-2" role='gridcell'>
            <div className="courses-user-list-actions">
              <button className="Button Button--icon-action addUserButton" onClick={this.addUserToCourse} type="button">
                <span className="screenreader-only">{I18n.t("Add Users to %{name}", {name: this.props.name})}</span>
                <i className="icon-plus" aria-hidden="true"></i>
              </button>
              <a className="Button Button--icon-action" href={`/courses/${this.props.id}/statistics`}>
                <span className="screenreader-only">{I18n.t("Go to statistics for %{name}", {name: this.props.name})}</span>
                <i className="icon-stats" aria-hidden="true"></i>
              </a>
              <a className="Button Button--icon-action" href={`/courses/${this.props.id}/settings`}>
                <span className="screenreader-only">{I18n.t("Go to settings for %{name}", {name: this.props.name})}</span>
                <i className="icon-settings" aria-hidden="true"></i>
              </a>
            </div>
          </div>
        </div>
      );
    }
  });

  return CoursesListRow;
});
