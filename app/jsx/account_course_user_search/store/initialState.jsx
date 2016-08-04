define([
  './tabList'
], function (tabList) {

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
    },
    tabList: {
      basePath: '',
      tabs: tabList,
      selected: 0
    }
  };


  return initialState;
});

