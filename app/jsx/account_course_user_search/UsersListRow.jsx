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
      let { accountId, id, name, sis_user_id, email, avatar_url, last_login } = this.props;
      let url = `/accounts/${accountId}/users/${id}`;

      return (
        <div role='row' className="grid-row pad-box-mini border border-b">
          <div className="col-md-3" role="gridcell">
            <span className="userAvatar">
              {!!avatar_url &&
                <span className="ic-avatar" style={{width: 30, height: 30, margin: "-1px 10px 1px 0"}}>
                  <img src={avatar_url} />
                </span>
              }
            </span>
            <span className="userUrl">
              <a href={url}>{name}</a>
            </span>
          </div>
          <div className="col-md-3" role='gridcell'>
            {email}
          </div>

          <div className="col-md-3" role='gridcell'>
            {sis_user_id}
          </div>

          <div className="col-md-3" role='gridcell'>
            {$.datetimeString(last_login)}
          </div>
        </div>
      );
    }
  });

  return UsersListRow;
});
