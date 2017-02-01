define([
  'react',
  'i18n!account_course_user_search',
  'underscore',
  './NewUserModal',
  './IcInput',
], (React, I18n, _, NewUserModal, IcInput) => {
  const { string, bool, func, object } = React.PropTypes

  var UsersToolbar = React.createClass({
    propTypes: {
      onUpdateFilters: func.isRequired,
      onApplyFilters: func.isRequired,
      isLoading: bool,

      search_term: string,
      errors: object,
      accountId: string
    },

    applyFilters(e) {
      e.preventDefault();
      this.props.onApplyFilters();
    },

    addUser() {
      this.refs.addUser.openModal();
    },

    render () {
      const { onUpdateFilters, isLoading, errors } = this.props

      var addUserButton;
      if (window.ENV.PERMISSIONS.can_create_users) {
        addUserButton =
          <button className="Button add_user" type="button" onClick={this.addUser}>
            <i className="icon-plus" />
            {" "}
            {I18n.t("People")}
          </button>
      }

      return (
        <div>
          <form
            className="user_search_bar"
            style={{opacity: isLoading ? 0.5 : 1}}
            onSubmit={this.applyFilters}
            disabled={isLoading}
          >
            <div className="grid-row">
              <div className="col-xs-12 col-md-9">
                <div className="users-list-toolbar-form">
                  <IcInput
                    value={this.props.search_term}
                    placeholder={I18n.t("Search users...")}
                    onChange={(e) => onUpdateFilters({search_term: e.target.value})}
                    error={errors.search_term}
                  />
                  &nbsp;
                  <div className="ic-Form-control">
                    <button className="Button">
                      {I18n.t("Go")}
                    </button>
                  </div>
                </div>
              </div>
              <div className="col-xs-12 col-md-3">
                <div className="users-list-toolbar-actions">
                  <div className="users-list-toolbar-actions__layout">
                    {addUserButton}
                    &nbsp;
                    <div className="al-dropdown__container">
                      <button id="peopleOptionsBtn" className="al-trigger Button" type="button">
                        <i className="icon-more"></i>
                        <span className="screenreader-only">{I18n.t('People Options')}</span>
                      </button>
                      <ul className="al-options" role="menu" aria-hidden="true">
                        <li>
                          <a
                            href={`/accounts/${this.props.accountId}/avatars`}
                            className="icon-student-view" id="manageStudentsLink"
                            role="menuitem">
                              {I18n.t('Manage profile pictures')}
                          </a>
                        </li>
                        <li>
                          <a
                            href={`/accounts/${this.props.accountId}/groups`}
                            className="icon-group"
                            id="viewUserGroupLink"
                            role="menuitem">
                              {I18n.t('View user groups')}
                          </a>
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </form>
          <NewUserModal ref="addUser" userList={this.props.userList} handlers={this.props.handlers} />
        </div>
      );
    }
  });

  return UsersToolbar;
});
