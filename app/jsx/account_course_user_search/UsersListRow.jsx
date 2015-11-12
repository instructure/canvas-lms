define([
  "react",
  "i18n!account_course_user_search",
  'jquery',
  'jquery.instructure_date_and_time'
], function(React, I18n, $) {

  var { number, string, func, shape, arrayOf } = React.PropTypes;

  var UsersListRow = React.createClass({
    propTypes: {
      accountId: string,
      id: string.isRequired,
      name: string.isRequired,
      sis_user_id: string,
      email: string,
      avatar_url: string,
      last_login: string
    },

    render() {
      var { accountId, id, name, sis_user_id, email, avatar_url, last_login } = this.props;
      var url = `/accounts/${accountId}/users/${id}`;

      return (
        <tr>
          <td>
            {!!avatar_url &&
              <span className="ic-avatar" style={{width: 30, height: 30, margin: "-1px 10px 1px 0"}}>
                <img src={avatar_url} />
              </span>
            }
            <a href={url} className="user_link">{name}</a>
          </td>
          <td>
            {email}
          </td>
          <td>
            {sis_user_id}
          </td>
          <td>
            {$.datetimeString(last_login)}
          </td>
          <td>
          </td>
        </tr>
      );
    }
  });

  return UsersListRow;
});
