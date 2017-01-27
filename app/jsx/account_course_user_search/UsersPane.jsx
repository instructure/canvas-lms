import React from 'react'
import I18n from 'i18n!account_course_user_search'
import _ from 'underscore'
import UsersStore from './UsersStore'
import UsersList from './UsersList'
import UsersToolbar from './UsersToolbar'
import renderSearchMessage from './renderSearchMessage'
import configureStore from './store/configureStore'
import UserActions from './actions/UserActions'

  const MIN_SEARCH_LENGTH = 3;

  var UsersPane = React.createClass({
    propTypes: {
      store: React.PropTypes.object
    },

    getInitialState () {
      return this.props.store.getState().userList;
    },
    componentDidMount () {
      this.unsubscribe = this.props.store.subscribe(this.handleStateChange);
      this.props.store.dispatch(UserActions.apiGetUsers());
    },
    componentWillUnmount () {
      this.unsubscribe();
    },
    handleStateChange () {
      this.setState(this.props.store.getState().userList);
    },
    fetchMoreUsers () {
      UsersStore.loadMore(this.state.filters);
    },
    handleApplyingSearchFilter () {
      this.props.store.dispatch(UserActions.applySearchFilter(MIN_SEARCH_LENGTH));
    },
    handleUpdateSearchFilter (searchFilter) {
      this.props.store.dispatch(UserActions.updateSearchFilter(searchFilter));
    },
    handleSubmitEditUserForm (attributes, id) {
      this.props.store.dispatch(UserActions.apiUpdateUser(attributes, id));
    },
    handleOpenEditUserDialog (user) {
      this.props.store.dispatch(UserActions.openEditUserDialog(user));
    },
    handleCloseEditUserDialog (user) {
      this.props.store.dispatch(UserActions.closeEditUserDialog(user));
    },
    handleGetMoreUsers () {
      this.props.store.dispatch(UserActions.getMoreUsers());
    },
    handleAddNewUser (attributes) {
      this.props.store.dispatch(UserActions.apiCreateUser(this.state.accountId, attributes));
    },
    handleAddNewUserFormErrors (errors) {
      for (const key in errors) {
        this.props.store.dispatch(UserActions.addError({[key]: errors[key]}));
      }
    },
    render () {
      const {next, timezones, accountId, users, isLoading, errors, searchFilter} = this.state;
      const collection = {data: users, loading: isLoading, next: next};
      return (
        <div>
          {<UsersToolbar
              onUpdateFilters={this.handleUpdateSearchFilter}
              onApplyFilters={this.handleApplyingSearchFilter}
              isLoading={isLoading}
              errors={errors}
              {...searchFilter}
              accountId={accountId.toString()}
              handlers={{
                handleAddNewUser: this.handleAddNewUser,
                handleAddNewUserFormErrors: this.handleAddNewUserFormErrors
              }}
              userList={this.state}
          />}

          {!_.isEmpty(users) &&
            <UsersList
              timezones={timezones}
              accountId={accountId.toString()}
              users={users}
              handlers={{
                handleSubmitEditUserForm: this.handleSubmitEditUserForm,
                handleOpenEditUserDialog: this.handleOpenEditUserDialog,
                handleCloseEditUserDialog: this.handleCloseEditUserDialog
              }}
              permissions={this.state.permissions}
            />
          }

          {renderSearchMessage(collection, this.handleGetMoreUsers, I18n.t("No users found"))}
        </div>
      );
    }
  });

export default UsersPane
