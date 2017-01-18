define ([
  "jquery",
  "jsx/account_course_user_search/UsersStore",
  "underscore",
  "i18n!user_actions"
], ($, UsersStore, _, I18n) => {

  const UserActions = {
    apiCreateUser (accountId, attributes) {
      return (dispatch, getState) => {

        UsersStore.create(attributes).then((response, _, xhr) => {
          dispatch(this.addToUsers([response], xhr));
        });
      };
    },

    addError (error) {
      return {
        type: 'ADD_ERROR',
        error
      };
    },

    apiGetUsers () {
      return (dispatch, getState) => {
        let users = getState().userList.users;
        if (_.isEmpty(users)) {
          UsersStore.load({search_term: ''}).then((response, _, xhr) => {
            dispatch(this.gotUserList(response, xhr));
          });
        } else {
          dispatch(this.gotUserList(users));
        }
      };
    },

    apiUpdateUser(attributes, userId) {
      return (dispatch, getState) => {
        let url = `/api/v1/users/${userId}`;
        $.ajaxJSON(url, "PUT", {user: attributes}).then((response) => {
          dispatch(this.gotUserUpdate(response));
        });
      };
    },

    gotUserList (users, xhr) {
      return {
        type: 'GOT_USERS',
        payload: {
          users: users,
          xhr: xhr
        }
      };
    },

    gotUserUpdate (user) {
      return {
        type: 'GOT_USER_UPDATE',
        payload: user
      };
    },

    openEditUserDialog (user) {
      return {
        type: 'OPEN_EDIT_USER_DIALOG',
        payload: user
      };
    },

    closeEditUserDialog (user) {
      return {
        type: 'CLOSE_EDIT_USER_DIALOG',
        payload: user
      };
    },

    updateSearchFilter (filter) {
      return {
        type: 'UPDATE_SEARCH_FILTER',
        payload: filter
      };
    },

    displaySearchTermTooShortError (minSearchLength) {
      return {
        type: 'SEARCH_TERM_TOO_SHORT',
        errors: {
          termTooShort: I18n.t("Search term must be at least %{num} characters", {num: minSearchLength})
        }
      };
    },

    loadingUsers () {
      return {
        type: 'LOADING_USERS'
      };
    },

    addToUsers (users, xhr) {
      return {
        type: 'ADD_TO_USERS',
        payload: {
          users: users,
          xhr: xhr
        }
      };
    },

    getMoreUsers (store = UsersStore) {
      return (dispatch, getState) => {
        let searchFilter = getState().userList.searchFilter;
        dispatch(this.loadingUsers());
        store.loadMore(searchFilter).then((response, _, xhr) => {
          dispatch(this.addToUsers(response, xhr));
        });
      };
    },

    applySearchFilter (minSearchLength, store = UsersStore) {
      return (dispatch, getState) => {
        let searchFilter = getState().userList.searchFilter;

        if (searchFilter.search_term.length >= minSearchLength || searchFilter.search_term === "") {
          dispatch(this.loadingUsers());
          store.load(searchFilter).then((response, _, xhr) => {
            dispatch(this.gotUserList(response, xhr));
          });
        } else {
          dispatch(this.displaySearchTermTooShortError(minSearchLength));
        }

      };
    }
  };

  return UserActions;
});
