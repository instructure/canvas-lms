define([
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./UsersListRow",
], function(React, I18n, _, UsersListRow) {

  var { number, string, func, shape, arrayOf } = React.PropTypes;

  var UsersList = React.createClass({
    propTypes: {
      accountId: React.PropTypes.string,
      users: arrayOf(shape(UsersListRow.propTypes)).isRequired
    },

    render() {
      var { users } = this.props;

      return (
        <div className="content-box" role='grid'>
          <div role='row' className="grid-row border border-b pad-box-mini">
            <div role='columnheader' className="col-md-3">
              <strong><small>{I18n.t("Name")}</small></strong>
            </div>
            <div role='columnheader' className="col-md-3">
              <strong><small>{I18n.t("Email")}</small></strong>
            </div>
            <div role='columnheader' className="col-md-3">
              <strong><small>{I18n.t("SIS ID")}</small></strong>
            </div>
            <div role='columnheader' className="col-md-3">
              <strong><small>{I18n.t("Last Login")}</small></strong>
            </div>
          </div>

          <div className='users-list' role='rowgroup'>
            {users.map((user) => <UsersListRow key={user.id} accountId={this.props.accountId} {...user} />)}
          </div>
        </div>
      );
    }
  });

  return UsersList;
});
