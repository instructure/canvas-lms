define([
  'redux',
  'redux-thunk',
], (redux, {default: ReduxThunk}) => {
  // returns createStore(reducer, initialState)
  const createStore = redux.applyMiddleware(
    ReduxThunk
  )(redux.createStore);

  const defaultState = {
    courseParams: {
      courseId: '',             // the course ID
      roles: [],                // the roles available to assign people to
      sections: [],             // the sections in this course
      inviteUser: false     // can the current user invite new users into a course?
    },
    inputParams: {
      searchType: 'cc_path',    // cc_path=email, unique_id=login_id, sis_user_id=sis_user_id
      nameList: '',             // user entered list of names to add to this course
      role: '',                 // the role to assign each of the added users
      section: '',              // the section to assign each of the added users
      limitPrivilege: false,    // user can interact with users in their section only
      canReadSIS: true
    },
    apiState: {
      pendingCount: 0,         // >0 while api calls are in-flight
      error: undefined,    //api error message
    },
    userValidationResult: {
      validUsers: [],       // the validated users
      duplicates: {},       // key: address, value: instance of duplicateShape
      missing: {}           // key: address, value: instance of missingShape
    },
    usersToBeEnrolled: [],  // [{user_id, name, email, ...}]
    usersEnrolled: false    // true when students have been enrolled and we're finished
  };

  return {createStore, defaultState};
});
