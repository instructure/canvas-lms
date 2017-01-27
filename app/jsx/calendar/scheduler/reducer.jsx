import { handleActions } from 'redux-actions'
import SchedulerActions from './actions'
import initialState from './store/initialState'

  const reducer = handleActions({
    [SchedulerActions.keys.SET_FIND_APPOINTMENT_MODE]: (state = initialState, action) => {
      return {
        ...state,
        inFindAppointmentMode: action.payload
      }
    },
    [SchedulerActions.keys.SET_COURSE]: (state = initialState, action) => {
      return {
        ...state,
        selectedCourse: action.payload
      }
    }
  });

export default reducer
