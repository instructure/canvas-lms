define([
  'jsx/account_course_user_search/actions/UserActions',
  'jsx/account_course_user_search/UsersStore'
  ], (actions, UserStore) => {

  const STUDENTS = [
    {
        "id": "46",
        "name": "Irene Adler",
        "sortable_name": "Adler, Irene",
        "short_name": "Irene Adler",
        "sis_user_id": "957",
        "integration_id": null,
        "sis_login_id": "student57",
        "sis_import_id": "1",
        "login_id": "student57",
        "email": "brotherhood@example.com",
        "last_login": null,
        "time_zone": "Mountain Time (US & Canada)"
    },
    {
        "id": "44",
        "name": "Saint-John Allerdyce",
        "sortable_name": "Allerdyce, Saint-John",
        "short_name": "Saint-John Allerdyce",
        "sis_user_id": "955",
        "integration_id": null,
        "sis_login_id": "student55",
        "sis_import_id": "1",
        "login_id": "student55",
        "email": "brotherhood@example.com",
        "last_login": null,
        "time_zone": "Mountain Time (US & Canada)"
    },
    {
        "id": "52",
        "name": "Michael Baer",
        "sortable_name": "Baer, Michael",
        "short_name": "Michael Baer",
        "sis_user_id": "963",
        "integration_id": null,
        "sis_login_id": "student63",
        "sis_import_id": "1",
        "login_id": "student63",
        "email": "marauders@example.com",
        "last_login": null,
        "time_zone": "Mountain Time (US & Canada)"
    }];

  QUnit.module('Account Course User Search Actions');

  asyncTest('apiCreateUser', () => {
    const server = sinon.fakeServer.create();
    UserStore.reset({accountId: 1});

    server.respondWith('POST', '/api/v1/accounts/1/users',
      [200, { "Content-Type": "application/json" }, JSON.stringify(STUDENTS[0])]
    );

    equal(typeof actions.apiCreateUser(1, {}), 'function', 'it initally returns a callback function');

    actions.apiCreateUser(1, {})((response) => {
      equal(response.type, 'ADD_TO_USERS', 'it dispatches the proper action');
      equal(Array.isArray(response.payload.users), true, 'it returns a users array');
      start();
    });

    server.respond();
    server.restore();
  });

  test('addError', () => {
    const message = actions.addError({errorKey: 'error'});
    equal(message.type, 'ADD_ERROR', 'it returns the proper action type');
    deepEqual(message.error, {errorKey: 'error'}, 'it returns the proper error');
  });

  asyncTest('apiGetUsers', () => {

    // This will let us start the tests back once all the async stuff finishes.
    let counter = 2;
    function done () {
      --counter || start();
    }

    const server = sinon.fakeServer.create();
    UserStore.reset({accountId: 1});

    server.respondWith('GET', /api\/v1\/accounts\/1\/users/,
      [200, { "Content-Type": "application/json" }, JSON.stringify(STUDENTS)]
    );

    equal(typeof actions.apiGetUsers(), 'function', 'it initally returns a callback function');

    actions.apiGetUsers()((response) => {
      equal(response.type, 'GOT_USERS', 'it returns the proper action type');
      deepEqual(response.payload.users, STUDENTS, 'it returns the proper data');
      ok(response.payload.xhr, 'it calls out to the api when state has no users');
      done();
    }, () => {
      return {
        userList: {
          users: []
        }
      }
    });

    actions.apiGetUsers()((response) => {
      deepEqual(response.payload.users, STUDENTS, 'it returns the proper data');
      ok(!response.payload.xhr, 'it does not call the api when there is state in the store');
      done();
    }, () => {
      return {
        userList: {
          users: STUDENTS
        }
      }
    });

    server.respond();
    server.restore();

  });

  asyncTest('apiUpdateUser', () => {
    const server = sinon.fakeServer.create();

    // This is a POST rather than a PUT because of the way our $.getJSON converts
    // non-GET requests to posts anyways.
    server.respondWith('POST', /api\/v1\/users\/1/,
      [200, { "Content-Type": "application/json" }, JSON.stringify(STUDENTS[0])]
    );

    equal(typeof actions.apiUpdateUser({name: 'Test'}, 1), 'function', 'it initally returns a callback function');

    actions.apiUpdateUser({name: 'Test'}, 1)((response) => {
      equal(response.type, 'GOT_USER_UPDATE', 'it returns the proper action type');
      deepEqual(response.payload, STUDENTS[0], 'it returns the user in the payload');
      start();
    });

    server.respond();
    server.restore();


  });

  test('openEditUserDialog', () => {
    const message = actions.openEditUserDialog(STUDENTS[0]);
    equal(message.type, 'OPEN_EDIT_USER_DIALOG', 'it returns the proper type');
    deepEqual(message.payload, STUDENTS[0], 'the payload contains the user');
  });

  test('closeEditUserDialog', () => {
    const message = actions.closeEditUserDialog(STUDENTS[0]);
    equal(message.type, 'CLOSE_EDIT_USER_DIALOG', 'it returns the proper type');
    deepEqual(message.payload, STUDENTS[0], 'the payload contains the user');
  });

  test('updateSearchFilter', () => {
    const message = actions.updateSearchFilter('myFilter');
    equal(message.type, 'UPDATE_SEARCH_FILTER', 'it returns the proper type');
    equal(message.payload, 'myFilter', 'the payload contains the filter');
  });

  test('displaySearchTermTooShortError', () => {
    const message = actions.displaySearchTermTooShortError(3);
    equal(message.type, 'SEARCH_TERM_TOO_SHORT', 'it returns the proper type');
    equal(message.errors.termTooShort, 'Search term must be at least 3 characters', 'the error is set with the proper number');
  });

  test('loadingUsers', () => {
    const message = actions.loadingUsers();
    equal(message.type, 'LOADING_USERS', 'it returns the proper type');
  });

  asyncTest('getMoreUsers', () => {

    let count = 2;
    const done = () => {
      --count || start();
    };

    const fakeDispatcher = (response) => {
      if (count === 2) {
        equal(response.type, 'LOADING_USERS', 'it returns the proper action type');
        done();
      } else {
        equal(response.type, 'ADD_TO_USERS', 'it returns the proper action type');
        deepEqual(response.payload.users[0], STUDENTS[0], 'it returns the user in the payload');
        done();
      }

    };

    const fakeGetState = () => {
      return {
        userList: {
          searchFilter: 'abc',
          next: '/api/v1/accounts/1/users?page=2'
        }
      };
    };

    const fakeUserStore = {
      loadMore (filter) {
        return Promise.resolve([STUDENTS[0]])
      }
    }

    const actionThunk = actions.getMoreUsers(fakeUserStore);

    equal(typeof actionThunk, 'function', 'it initally returns a callback function');

    actionThunk(fakeDispatcher, fakeGetState);

  });

  asyncTest('applySearchFilter', () => {
    let count = 3;
    const done = () => {
      --count || start();
    };

    const fakeDispatcherSearchLengthOkay = (response) => {
      if (count === 3) {
        equal(response.type, 'LOADING_USERS', 'it returns the proper action type');
        done();
      } else {
        equal(response.type, 'GOT_USERS', 'it returns the proper action type');
        deepEqual(response.payload.users[0], STUDENTS[0], 'it returns the user in the payload');
        done();
      }

    };

    const fakeGetStateSearchLengthOkay = () => {
      return {
        userList: {
          searchFilter: {
            search_term: 'abcd'
          }
        }
      };
    };

    const fakeDispatcherSearchLengthTooShort = (response) => {
      equal(response.type, 'SEARCH_TERM_TOO_SHORT', 'it returns the proper action type');
      equal(response.errors.termTooShort, 'Search term must be at least 4 characters', 'the error is set with the proper number');
      done();
    };

    const fakeGetStateSearchLengthTooShort = () => {
      return {
        userList: {
          searchFilter: {
            search_term: 'a'
          }
        }
      };
    };

    const fakeUserStore = {
      load (filter) {
        return Promise.resolve([STUDENTS[0]]);
      }
    }

    const actionThunk = actions.applySearchFilter(4, fakeUserStore);

    equal(typeof actionThunk, 'function', 'it initally returns a callback function');

    actionThunk(fakeDispatcherSearchLengthOkay, fakeGetStateSearchLengthOkay);
    actionThunk(fakeDispatcherSearchLengthTooShort, fakeGetStateSearchLengthTooShort);
  });


});