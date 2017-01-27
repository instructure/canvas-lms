import { createStore, applyMiddleware, combineReducers } from 'redux'
import ReduxThunk from 'redux-thunk'
import ltiCollaboratorsReducer from '../reducers/ltiCollaboratorsReducer'
import listCollaborationsReducer from '../reducers/listCollaborationsReducer'
import deleteCollaborationReducer from '../reducers/deleteCollaborationReducer'
import createCollaborationReducer from '../reducers/createCollaborationReducer'
import updateCollaborationReducer from '../reducers/updateCollaborationReducer'

const createStoreWithMiddleware = applyMiddleware(
  ReduxThunk
)(createStore);

const collaboratorationsReducer = combineReducers({
  ltiCollaborators: ltiCollaboratorsReducer,
  listCollaborations: listCollaborationsReducer,
  deleteCollaboration: deleteCollaborationReducer,
  createCollaboration: createCollaborationReducer,
  updateCollaboration: updateCollaborationReducer
});

export default createStoreWithMiddleware(collaboratorationsReducer)
