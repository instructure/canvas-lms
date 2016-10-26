define([
  'redux-actions',
  './api_client'
], ({ createActions }, api) => {
  const actionDefs = [
    'SET_INPUT_PARAMS',

    'VALIDATE_USERS_START',     // validate users api lifecycle
    'VALIDATE_USERS_SUCCESS',
    'VALIDATE_USERS_ERROR',

    'CREATE_USERS_START',       // invite users api lifecycle
    'CREATE_USERS_SUCCESS',
    'CREATE_USERS_ERROR',

    'ENROLL_USERS_START',       // enrols users api lifecycle
    'ENROLL_USERS_SUCCESS',
    'ENROLL_USERS_ERROR',

    'CHOOSE_DUPLICATE',           // choose from a set of duplicates
    'SKIP_DUPLICATE',             // skip this set of duplicates
    'ENQUEUE_NEW_FOR_DUPLICATE',  // prepare to create a new user in lieu of one of the duplicates
    'ENQUEUE_NEW_FOR_MISSING',    // prepare to create a new user for one of the missing users

    'ENQUEUE_USERS_TO_BE_ENROLLED', // prepare to enroll validated users

    'RESET'   // reset([array of state subsections to reset]) undefined or empty = reset everything
  ];

  const actionTypes = actionDefs.reduce((types, action) => {
    types[action] = action;   // eslint-disable-line no-param-reassign
    return types;
  }, {});

  const actions = createActions(...actionDefs);

  actions.validateUsers = () => (dispatch, getState) => {
    dispatch(actions.validateUsersStart());
    const state = getState();
    const courseId = state.courseParams.courseId;
    const users = state.inputParams.nameList;
    const searchType = state.inputParams.searchType;
    api.validateUsers({ courseId, users, searchType })
      .then((res) => {
        dispatch(actions.validateUsersSuccess(res.data));
        // if all the users were found, then we can jump right to enrolling
        if (res.data.duplicates.length === 0 && res.data.missing.length === 0) {
          const st = getState();
          dispatch(actions.enqueueUsersToBeEnrolled(st.userValidationResult.validUsers));
        }
      })
      .catch((err) => {
        dispatch(actions.validateUsersError(err));
      });
  };


  actions.resolveValidationIssues = () => (dispatch, getState) => {
    dispatch(actions.createUsersStart());
    const state = getState();
    const courseId = state.courseParams.courseId;

    // the list of users to be enrolled
    let usersToBeEnrolled = state.userValidationResult.validUsers.slice();
    // and the list of users to be created
    const usersToBeCreated = [];

    Object.keys(state.userValidationResult.duplicates).forEach((addr) => {
      const dupeSet = state.userValidationResult.duplicates[addr];
      if (dupeSet.createNew && dupeSet.newUserInfo.name && dupeSet.newUserInfo.email) {
        usersToBeCreated.push(dupeSet.newUserInfo);
      } else if (dupeSet.selectedUserId >= 0) {
        const selectedUser = dupeSet.userList.find(u => u.user_id === dupeSet.selectedUserId);
        usersToBeEnrolled.push(selectedUser);
      }
    });
    Object.keys(state.userValidationResult.missing).forEach((addr) => {
      const missing = state.userValidationResult.missing[addr];
      if (missing.createNew && missing.newUserInfo.name && missing.newUserInfo.email) {
        usersToBeCreated.push(missing.newUserInfo);
      }
    });

    api.createUsers({ courseId, users: usersToBeCreated })
      .then((res) => {
        dispatch(actions.createUsersSuccess(res.data));
        // merge in the newly created users
        usersToBeEnrolled = usersToBeEnrolled.concat(res.data.invited_users.map((u) => {
          // adjust shape of users we just invited to match the existing users
          const user = { ...u }
          user.user_name = u.name;
          user.address = u.email;
          return user;
        }));
        dispatch(actions.enqueueUsersToBeEnrolled(usersToBeEnrolled));
      })
      .catch(err => dispatch(actions.createUsersError(err)));
  };

  actions.enrollUsers = () => (dispatch, getState) => {
    dispatch(actions.enrollUsersStart());
    const state = getState();
    const courseId = state.courseParams.courseId;
    const users = state.usersToBeEnrolled.map(u => u.user_id);
    const role = state.inputParams.role
          || (state.courseParams.roles && state.courseParams.roles.length && state.courseParams.roles[0].id)
          || '';
    const section = state.inputParams.section
          || (state.courseParams.sections && state.courseParams.sections.length && state.courseParams.sections[0].id)
          || '';
    const limitPrivilege = state.inputParams.limitPrivilege || false;
    api.enrollUsers({ courseId, users, role, section, limitPrivilege })
      .then(res => dispatch(actions.enrollUsersSuccess(res.data)))
      .catch(err => dispatch(actions.enrollUsersError(err)));
  };
  return { actions, actionTypes };
});
