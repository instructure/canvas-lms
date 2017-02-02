import redux from 'redux'
import { handleActions } from 'redux-actions'
import {actionTypes} from '../actions'
import '../store'

export default handleActions({
  [actionTypes.ENROLL_USERS_SUCCESS]: (/* state, action */) => true,
  [actionTypes.RESET]: (/* state, action */) => false
}, false)
