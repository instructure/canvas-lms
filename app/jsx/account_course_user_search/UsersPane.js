/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import _ from 'underscore'
import UsersStore from './UsersStore'
import UsersList from './UsersList'
import UsersToolbar from './UsersToolbar'
import renderSearchMessage from './renderSearchMessage'
import UserActions from './actions/UserActions'

const MIN_SEARCH_LENGTH = 3;

class UsersPane extends React.Component {
  static propTypes = {
    store: PropTypes.shape({
      getState: PropTypes.func.isRequired,
      dispatch: PropTypes.func.isRequired,
      subscribe: PropTypes.func.isRequired,
    }).isRequired,
    roles: PropTypes.arrayOf(PropTypes.string).isRequired,
  };

  constructor (props) {
    super(props)

    this.state = {
      userList: props.store.getState().userList,
    }
  }

  componentDidMount = () => {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange);
    this.props.store.dispatch(UserActions.apiGetUsers());
  }

  componentWillUnmount = () => {
    this.unsubscribe();
  }

  handleStateChange = () => {
    this.setState({userList: this.props.store.getState().userList});
  }

  fetchMoreUsers = () => {
    UsersStore.loadMore(this.state.userList.filters);
  }

  handleApplyingSearchFilter = () => {
    this.props.store.dispatch(UserActions.applySearchFilter(MIN_SEARCH_LENGTH));
  }

  debouncedDispatchApplySearchFilter = _.debounce(() => {
    this.props.store.dispatch(UserActions.applySearchFilter(MIN_SEARCH_LENGTH));
  }, 250);

  handleUpdateSearchFilter = (searchFilter) => {
    this.props.store.dispatch(UserActions.updateSearchFilter(searchFilter));
    this.debouncedDispatchApplySearchFilter();
  }

  handleSubmitEditUserForm = (attributes, id) => {
    this.props.store.dispatch(UserActions.apiUpdateUser(attributes, id));
  }

  handleOpenEditUserDialog = (user) => {
    this.props.store.dispatch(UserActions.openEditUserDialog(user));
  }

  handleCloseEditUserDialog = (user) => {
    this.props.store.dispatch(UserActions.closeEditUserDialog(user));
  }

  handleGetMoreUsers = () => {
    this.props.store.dispatch(UserActions.getMoreUsers());
  }

  handleAddNewUser = (attributes) => {
    this.props.store.dispatch(UserActions.apiCreateUser(this.state.userList.accountId, attributes));
  }

  handleAddNewUserFormErrors = (errors) => {
    for (const key in errors) {
      this.props.store.dispatch(UserActions.addError({[key]: errors[key]}));
    }
  }

  render () {
    const {next, timezones, accountId, users, isLoading, errors, searchFilter} = this.state.userList;
    const collection = {data: users, loading: isLoading, next};
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
          userList={this.state.userList}
          roles={this.props.roles}
        />}

        {!_.isEmpty(users) &&
        <UsersList
          userList={this.state.userList}
          onUpdateFilters={this.handleUpdateSearchFilter}
          onApplyFilters={this.handleApplyingSearchFilter}
          timezones={timezones}
          accountId={accountId.toString()}
          users={users}
          handlers={{
            handleSubmitEditUserForm: this.handleSubmitEditUserForm,
            handleOpenEditUserDialog: this.handleOpenEditUserDialog,
            handleCloseEditUserDialog: this.handleCloseEditUserDialog
          }}
          permissions={this.state.userList.permissions}
        />
          }

        {renderSearchMessage(collection, this.handleGetMoreUsers, I18n.t('No users found'))}
      </div>
    );
  }
}

export default UsersPane
