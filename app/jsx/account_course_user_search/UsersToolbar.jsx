define([
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./NewUserModal",
  "./IcInput",
], function(React, I18n, _, NewUserModal, IcInput) {

  var { string, bool, func, object, arrayOf, shape } = React.PropTypes;

  var UsersToolbar = React.createClass({
    propTypes: {
      onUpdateFilters: func.isRequired,
      onApplyFilters: func.isRequired,
      isLoading: bool,

      search_term: string,
      errors: object,
    },

    applyFilters(e) {
      e.preventDefault();
      this.props.onApplyFilters();
    },

    addUser() {
      this.refs.addUser.openModal();
    },

    render() {
      var { onUpdateFilters, isLoading, search_term, errors } = this.props;

      var addUserButton;
      if (window.ENV.PERMISSIONS.can_create_users) {
        addUserButton = <div className="ic-Form-actions">
          <button className="btn add_user" type="button" onClick={this.addUser}>
            <i className="icon-plus" />
            {" "}
            {I18n.t("People")}
          </button>
        </div>
      }

      return (
        <div>
          <form
            className="ic-Form-group ic-Form-group--inline user_search_bar"
            style={{alignItems: "center", opacity: isLoading ? 0.5 : 1}}
            onSubmit={this.applyFilters}
            disabled={isLoading}
          >

            <IcInput
              value={search_term}
              placeholder={I18n.t("Search users...")}
              onChange={(e) => onUpdateFilters({search_term: e.target.value})}
              error={errors.search_term}
            />

            <div className="ic-Form-control" style={{flexGrow: 2}}>
              <button className="btn">
                {I18n.t("Go")}
              </button>
            </div>

            {addUserButton}
          </form>

          <NewUserModal ref="addUser"/>
        </div>
      );
    }
  });

  return UsersToolbar;
});
