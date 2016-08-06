define(['jsx/account_course_user_search/reducers/rootReducer'], (reducer) => {

  module('Account Course User Search Reducer');

  test('ADD_ERROR action reducer', () => {
    const initialState = {
      userList: {
        users: [],
        errors: []
      }
    };

    const action = {
      type: 'ADD_ERROR',
      error: {errorKey: 'test error'}
    };

    const newState = reducer(initialState, action);
    const errors = newState.userList.errors;
    equal(errors.errorKey, 'test error', 'sets the errors property');
  });

  test('ADD_TO_USERS action reducer', () => {
    const initialState = {
      userList: {
        users: [],
        isLoading: true,
        errors: {search_term: ''},
        next: undefined,
        searchFilter: {search_term: ''},
        timezones: [],
        permissions: [],
        accountId: '123'
      }
    };
    const action = {
      type: 'ADD_TO_USERS',
      payload: {
        users: [{
          id: '1',
          locale: null,
          login_id: 'some_email@example.com',
          name: 'someuser',
          short_name: 'someuser',
          sortable_name: 'someuser'
        }]
      }
    };

    const newState = reducer(initialState, action);
    const user = newState.userList.users[0]

    equal(user.email, 'some_email@example.com', 'creates an email property if needed');
  });

  test('GOT_USERS action reducer', () => {
    const initialState = {
      userList: {
        users: [],
        isLoading: true,
        errors: {search_term: ''},
        next: undefined,
        searchFilter: {search_term: ''},
        timezones: [],
        permissions: [],
        accountId: '123'
      }
    };
    const action = {
      type: 'GOT_USERS',
      payload: {
        users: [{
          id: '1',
          locale: null,
          login_id: 'some_email@example.com',
          name: 'someuser',
          short_name: 'someuser',
          sortable_name: 'someuser'
        }],
        xhr: {
          getResponseHeader (header) {
            return '<http://canvas/api/v1/accounts/1/users?page=2>; rel="current",' +
                   '<http://canvas/api/v1/accounts/1/users?page=3>; rel="next",' +
                   '<http://canvas/api/v1/accounts/1/users?page=1>; rel="prev",' +
                   '<http://canvas/api/v1/accounts/1/users?page=1>; rel="first",' +
                   '<http://canvas/api/v1/accounts/1/users?page=5>; rel="last"';
          }
        }
      }
    };

    const newState = reducer(initialState, action);
    equal(newState.userList.next, 'http://canvas/api/v1/accounts/1/users?page=3', 'sets the next property');
    equal(newState.userList.isLoading, false, 'sets the isLoading property to false');
    equal(newState.userList.users, action.payload.users, 'set the users property.');
  });

  test('GOT_USER_UPDATE action reducer', () => {
    const initialState = {
      userList: {
        users: [{
          id: '1',
          locale: null,
          login_id: 'some_email@example.com',
          name: 'someuser',
          short_name: 'someuser',
          sortable_name: 'someuser'
        }],
        isLoading: true,
        errors: {search_term: ''},
        next: undefined,
        searchFilter: {search_term: ''},
        timezones: [],
        permissions: [],
        accountId: '123'
      }
    };
    const action = {
      type: 'GOT_USER_UPDATE',
      payload: {
        id: '1',
        name: 'aNewName'
      }
    };

    const newState = reducer(initialState, action);
    deepEqual(newState.userList.users[0], action.payload, 'sets the user to the updated user');
  });

  test('OPEN_EDIT_USER_DIALOG action reducer', () => {
    const initialState = {
      userList: {
        users: [{
          id: '1',
          locale: null,
          login_id: 'some_email@example.com',
          name: 'someuser',
          short_name: 'someuser',
          sortable_name: 'someuser'
        }],
        isLoading: true,
        errors: {search_term: ''},
        next: undefined,
        searchFilter: {search_term: ''},
        timezones: [],
        permissions: [],
        accountId: '123'
      }
    };
    const action = {
      type: 'OPEN_EDIT_USER_DIALOG',
      payload: {
        id: '1',
        name: 'aNewName'
      }
    };

    const newState = reducer(initialState, action);
    equal(newState.userList.users[0].editUserDialogOpen, true, 'sets the open dialog property on the user');
  });

  test('CLOSE_EDIT_USER_DIALOG action reducer', () => {
    const initialState = {
      userList: {
        users: [{
          id: '1',
          locale: null,
          login_id: 'some_email@example.com',
          name: 'someuser',
          short_name: 'someuser',
          sortable_name: 'someuser',
          editUserDialogOpen: true
        }],
        isLoading: true,
        errors: {search_term: ''},
        next: undefined,
        searchFilter: {search_term: ''},
        timezones: [],
        permissions: [],
        accountId: '123'
      }
    };
    const action = {
      type: 'CLOSE_EDIT_USER_DIALOG',
      payload: {
        id: '1',
        name: 'aNewName'
      }
    };

    const newState = reducer(initialState, action);
    equal(newState.userList.users[0].editUserDialogOpen, false, 'sets the open dialog property on the user to false');
  });

  test('UPDATE_SEARCH_FILTER action reducer', () => {
    const initialState = {
      userList: {
        users: [{
          id: '1',
          locale: null,
          login_id: 'some_email@example.com',
          name: 'someuser',
          short_name: 'someuser',
          sortable_name: 'someuser',
        }],
        isLoading: true,
        errors: {},
        next: undefined,
        searchFilter: {search_term: ''},
        timezones: [],
        permissions: [],
        accountId: '123'
      }
    };
    const action = {
      type: 'UPDATE_SEARCH_FILTER',
      payload: {
        search_term: 'someuser'
      }
    };

    const newState = reducer(initialState, action);
    equal(newState.userList.searchFilter.search_term, action.payload.search_term, 'sets the search term property');
    equal(newState.userList.errors.search_term, '', 'sets the error for search term to empty string');
  });

  test('LOADING_USERS action reducer', () => {
    const initialState = {
      userList: {
        users: [{
          id: '1',
          locale: null,
          login_id: 'some_email@example.com',
          name: 'someuser',
          short_name: 'someuser',
          sortable_name: 'someuser',
        }],
        isLoading: false,
        errors: {},
        next: undefined,
        searchFilter: {search_term: ''},
        timezones: [],
        permissions: [],
        accountId: '123'
      }
    };
    const action = {
      type: 'LOADING_USERS',
      payload: {}
    };

    const newState = reducer(initialState, action);
    equal(newState.userList.isLoading, true, 'sets the loading property to true');
  });


  test('SELECT_TAB action reducer', () => {
    const initialState = {
      tabList: {
        basePath: '/accounts/1/search',
        tabs: [
          {
            title: 'Tab1',
            path: '/courses',
            permisssions:  []
          },
          {
            title: 'Tab2',
            path: '/courses',
            permisssions:  []
          }
        ],
        selected: 0
      }
    };
    const action = {
      type: 'SELECT_TAB',
      payload: {
        tabIndex: 1
      }
    };

    const newState = reducer(initialState, action);
    equal(newState.tabList.selected, 1, 'sets the selected tab property to 1');
  });


});
