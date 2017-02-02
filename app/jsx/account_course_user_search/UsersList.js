import React from 'react'
import I18n from 'i18n!account_course_user_search'
import _ from 'underscore'
import UsersListRow from './UsersListRow'

  var { string, array, object } = React.PropTypes;

  var UsersList = React.createClass({
    propTypes: {
      accountId: string.isRequired,
      users: array.isRequired,
      timezones: object.isRequired,
      permissions: object.isRequired,
      handlers: object.isRequired
    },

    render() {
      const { users, timezones, accountId } = this.props;

      return (
        <div className="content-box" role='grid'>
          <div role='row' className="grid-row border border-b pad-box-mini">
            <div role='columnheader' className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t("Name")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t("Email")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-1">
              <span className="courses-user-list-header">
                {I18n.t("SIS ID")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t("Last Login")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-2">
              <span className='screenreader-only'>{I18n.t("User option links")}</span>
            </div>
          </div>
          <div className='users-list' role='rowgroup'>
            {
              users.map((user) => {
                return (
                  <UsersListRow
                    handlers={this.props.handlers}
                    key={user.id}
                    timezones={timezones}
                    accountId={accountId}
                    user={user}
                    permissions={this.props.permissions}
                  />
                );
              })
            }
          </div>
        </div>
      );
    }
  });

export default UsersList
