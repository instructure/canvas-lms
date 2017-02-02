import { combineReducers } from 'redux'
import { handleActions } from 'redux-actions'
import {defaultState} from './store'
import {actions, actionTypes} from './actions'
import apiState from './reducers/apiState_reducer'
import inputParams from './reducers/inputParams_reducer'
import userValidationResult from './reducers/userValidationResult_reducer'
import usersToBeEnrolled from './reducers/usersToBeEnrolled_reducer'
import usersEnrolled from './reducers/usersEnrolled_reducer'

  const reducer = combineReducers({
    courseParams: handleActions({}, defaultState.courseParams),
    apiState,
    inputParams,
    userValidationResult,
    usersToBeEnrolled,
    usersEnrolled
  });

export default reducer
