define([
  "react",
  "i18n!account_course_user_search",
  'jquery',
  'jsx/shared/EditUserDetailsDialog',
  'jquery.instructure_date_and_time'
], function(React, I18n, $, EditUserDetailsDialog) {

  const { object, number, string, func, shape, arrayOf, bool } = React.PropTypes;

  var UsersListRow = React.createClass({
    propTypes: {
      accountId: string,
      timezones: object.isRequired,
      user: object.isRequired,
      handlers: shape({
        handleOpenEditUserDialog: func,
        handleSubmitEditUserForm: func,
        handleCloseEditUserDialog: func
      }).isRequired,
      permissions: shape({
        can_masquerade: bool,
        can_message_users: bool,
        can_edit_users: bool
      }).isRequired
    },

    renderLinks () {
      const links = [];
      const { id, name } = this.props.user;
      const { handleOpenEditUserDialog } = this.props.handlers;
      if (this.props.permissions.can_masquerade) {
        links.push(
          <a
            className="Button Button--icon-action user_actions_js_test"
            key="masqueradeLink"
            href={`/users/${id}/masquerade`}
          >
            <span className="screenreader-only">{I18n.t("Masquerade as %{name}", {name})}</span>
            <i className="icon-masquerade" aria-hidden="true"></i>
          </a>
        );
      }

      if (this.props.permissions.can_message_users) {
        links.push(
          <a
            className="Button Button--icon-action user_actions_js_test"
            key="messageUserLink"
            href={`/conversations?user_name=${name}&user_id=${id}`}
          >
            <span className="screenreader-only">{I18n.t("Send message to %{name}", {name})}</span>
            <i className="icon-message" aria-hidden="true"></i>
          </a>
        );
      }

      if (this.props.permissions.can_edit_users) {
        links.push(
          <button
            className="Button Button--icon-action user_actions_js_test"
            key="canEditUserLink"
            onClick={handleOpenEditUserDialog.bind(null, this.props.user)}
            type="button"
          >
            <span className="screenreader-only">{I18n.t("Edit %{name}", {name})}</span>
            <i className="icon-edit" aria-hidden="true"></i>
          </button>
        );
      }

      return (
        <div ref="linksContainer" className="courses-user-list-actions">
          {links}
        </div>
      );
    },

    render() {
      const { id, name, sis_user_id, email, avatar_url, last_login, editUserDialogOpen } = this.props.user;
      const { handleSubmitEditUserForm, handleCloseEditUserDialog } = this.props.handlers;
      const url = `/accounts/${this.props.accountId}/users/${id}`;

      return (
        <div role='row' className="grid-row middle-xs pad-box-mini border border-b">
          <div className="col-xs-3" role="gridcell">
            <div className="grid-row middle-xs">
              <span className="userAvatar">
                <span className="userUrl">
                  {!!avatar_url &&
                    <span className="ic-avatar UserListRow__Avatar">
                      <img src={avatar_url} alt={`User avatar for ${name}`} />
                    </span>
                  }
                  <a href={url}>{name}</a>
                </span>
              </span>
            </div>
          </div>
          <div className="col-xs-3" role='gridcell'>
            {email}
          </div>

          <div className="col-xs-1" role='gridcell'>
            {sis_user_id}
          </div>

          <div className="col-xs-3" role='gridcell'>
            {$.datetimeString(last_login)}
          </div>

          <div className="col-xs-2" role='gridcell'>
            {this.renderLinks()}
            <EditUserDetailsDialog
              submitEditUserForm={handleSubmitEditUserForm}
              user={this.props.user}
              timezones={this.props.timezones}
              isOpen={editUserDialogOpen}
              contentLabel={I18n.t('Edit User')}
              onRequestClose={handleCloseEditUserDialog.bind(null, this.props.user)}
            />
          </div>
        </div>
      );
    }
  });

  return UsersListRow;
});
