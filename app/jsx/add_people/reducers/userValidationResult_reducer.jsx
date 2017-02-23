define([
  'underscore',
  'redux',
  'redux-actions',
  '../actions',
  '../store'
], (_, redux, { handleActions }, {actions, actionTypes}, {defaultState}) => {
  // helpers -------------------------------
  // the api returns duplicates as nested arrays
  // inner array is of users sharing the searched address
  // outer array is for each of the searched address
  // this function transforms that into an object whose key
  // is the searched address, the userList is the corresponding array of users,
  // and adds other fields for the app
  function transformDupeApiResult (apiResult) {
    const retvalMap = {};
    if (apiResult) {
      apiResult.forEach((d) => {
        if (d.length) {
          retvalMap[d[0].address] = {
            address: d[0].address,
            selectedUserId: -1,
            skip: false,
            createNew: false,
            newUserInfo: undefined,
            userList: d
          }
        }
      });
    }
    return retvalMap;
  }

  // the api returns missing as an array of missing user results
  // this function transforms into an object keyed by the searched address,
  // with the searched address + supporting fields for the app
  function transformMissingApiResult (apiResult) {
    const retvalMap = {};
    if (apiResult) {
      apiResult.forEach((d) => {
        retvalMap[d.address] = {
          address: d.address,
          type: d.type,
          createNew: false,
          newUserInfo: {
            name: d.user_name || '',  // if the user entered a name as part of the email, it comes back in user_name
            email: d.type === 'email' ? d.address : ''
          }
        };
      });
    }
    return retvalMap;
  }

  // the module -----------------------------------
  return handleActions({
    // no action.payload
    [actionTypes.VALIDATE_USERS_START]: (state, /* action */) => {
      // reset state
      let newstate = _.cloneDeep(state);
      newstate = defaultState.userValidationResult;
      return newstate;
    },
    // action.payload: validateUsers api response
    [actionTypes.VALIDATE_USERS_SUCCESS]: (state, action) => {
      const newstate = _.cloneDeep(state);
      newstate.validUsers = action.payload.users;
      newstate.duplicates = transformDupeApiResult(action.payload.duplicates);
      newstate.missing = transformMissingApiResult(action.payload.missing);
      return newstate;
    },
    // action.payload: {address, user_id}
    [actionTypes.CHOOSE_DUPLICATE]: (state, action) => {
      const newstate = _.cloneDeep(state);
      const chosenOne = action.payload;
      // mark the duplicate as selected
      const duplicateSet = newstate.duplicates[chosenOne.address];
      duplicateSet.selectedUserId = chosenOne.user_id;
      duplicateSet.skip = false;
      duplicateSet.createNew = false;
      return newstate;
    },
    // action.payload: address
    [actionTypes.SKIP_DUPLICATE]: (state, action) => {
      const newstate = _.cloneDeep(state);
      const address = action.payload;
      const duplicateSet = newstate.duplicates[address];
      duplicateSet.selectedUserId = -1;
      duplicateSet.skip = true;
      duplicateSet.createNew = false;
      return newstate;
    },
    // action.payload: {address, newUserInfo}
    [actionTypes.ENQUEUE_NEW_FOR_DUPLICATE]: (state, action) => {
      const newstate = _.cloneDeep(state);
      const address = action.payload.address;
      const duplicateSet = newstate.duplicates[address];
      duplicateSet.selectedUserId = -1;
      duplicateSet.skip = false;
      duplicateSet.createNew = true;
      duplicateSet.newUserInfo = Object.assign({}, action.payload.newUserInfo);
      return newstate;
    },
    // action.payload: {address, newUserInfo}
    [actionTypes.ENQUEUE_NEW_FOR_MISSING]: (state, action) => {
      const newstate = _.cloneDeep(state);
      const address = action.payload.address;
      const newUserInfo = action.payload.newUserInfo;
      const missing = newstate.missing[address];
      if (missing) {
        if (newUserInfo === false) {
          // user has chosen not to create a new user for this missing one
          missing.createNew = false;
        } else {
          // user has chosen to create a new user for this midding one
          missing.createNew = true;
          missing.newUserInfo = Object.assign({}, newUserInfo);
        }
      }
      return newstate;
    },
    [actionTypes.CREATE_USERS_SUCCESS]: function creaeUsersReducer (state/* , action */) {
      return state; // noop
    },
    [actionTypes.RESET]: function resetReducer (state, action) {
      return (!action.payload || action.payload.includes('userValidationResult')) ? defaultState.userValidationResult : state;
    }

  }, defaultState.userValidationResult);
});
