define([
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./UsersStore",
  "./UsersList",
  "./UsersToolbar",
  "./renderSearchMessage"
], function(React, I18n, _, UsersStore, UsersList, UsersToolbar, renderSearchMessage) {

  var MIN_SEARCH_LENGTH = 3;

  var UsersPane = React.createClass({
    propTypes: {
      accountId: React.PropTypes.string,
    },

    getInitialState() {
      var filters = {
        search_term: ""
      };

      return {
        filters,
        draftFilters: filters,
        errors: {}
      }
    },

    componentWillMount() {
      UsersStore.addChangeListener(this.refresh);
    },

    componentDidMount() {
      this.fetchUsers();
    },

    componentWillUnmount() {
      UsersStore.removeChangeListener(this.refresh);
    },

    fetchUsers() {
      UsersStore.load(this.state.filters);
    },

    fetchMoreUsers() {
      UsersStore.loadMore(this.state.filters);
    },

    onUpdateFilters(newFilters) {
      this.setState({
        errors: {},
        draftFilters: _.extend({}, this.state.draftFilters, newFilters)
      });
    },

    onApplyFilters() {
      var filters = this.state.draftFilters;
      if (filters.search_term && filters.search_term.length < MIN_SEARCH_LENGTH) {
        this.setState({errors: {search_term: I18n.t("Search term must be at least %{num} characters", {num: MIN_SEARCH_LENGTH})}})
      } else {
        this.setState({filters, errors: {}}, this.fetchUsers);
      }
    },

    refresh() {
      this.forceUpdate();
    },

    render() {
      var { filters, draftFilters, errors } = this.state;
      var users = UsersStore.get(filters);
      var isLoading = !(users && !users.loading);

      return (
        <div>
          <UsersToolbar
            onUpdateFilters={this.onUpdateFilters}
            onApplyFilters={this.onApplyFilters}
            isLoading={isLoading}
            {...draftFilters}
            errors={errors}
          />

          {users && users.data &&
            <UsersList accountId={this.props.accountId} users={users.data} />
          }

          {renderSearchMessage(users, this.fetchMoreUsers, I18n.t("No users found"))}
        </div>
      );
    }
  });

  return UsersPane;
});

