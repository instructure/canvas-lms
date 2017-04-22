import { createStore, applyMiddleware } from 'redux'
import ReduxThunk from 'redux-thunk'
import rootReducer from './reducer'

const createStoreWithMiddleware = applyMiddleware(
  ReduxThunk
)(createStore)

function configStore (initialState) {
  return createStoreWithMiddleware(rootReducer, initialState)
}

export default configStore
