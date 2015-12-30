define([], function () {

  const initialState = {
    userList: {
      users: [],
      isLoading: true,
      errors: {search_term: ''},
      next: undefined,
      searchFilter: {search_term: ''},
      timezones: window.ENV.TIMEZONES,
      permissions: window.ENV.PERMISSIONS,
      accountId: window.ENV.ACCOUNT_ID
    }
  };

  return initialState;
});
