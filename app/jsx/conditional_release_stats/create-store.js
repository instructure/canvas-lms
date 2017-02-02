import { createStore, applyMiddleware } from 'redux'
import ReduxThunk from 'redux-thunk'
import rootReducer from './reducers/root-reducer'

const createStoreWithMiddleware = applyMiddleware(
  ReduxThunk
)(createStore)

function configureStore (initialState) {
  return createStoreWithMiddleware(rootReducer, initialState)
}

export default configureStore
