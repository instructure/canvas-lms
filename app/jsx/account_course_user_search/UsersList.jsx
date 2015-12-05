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
        <div className="pad-box no-sides">
          <table className="ic-Table users-list">
            <thead>
            <tr>
              <th>
                {I18n.t("Name")}
              </th>
              <th>
                {I18n.t("Email")}
              </th>
              <th>
                {I18n.t("SIS ID")}
              </th>
              <th>
                {I18n.t("Last Login")}
              </th>
              <th />
            </tr>
            </thead>

            <tbody>
            {users.map((user) => <UsersListRow key={user.id} accountId={this.props.accountId} {...user} />)}
            </tbody>
          </table>
        </div>
      );
    }
  });

  return UsersList;
});
