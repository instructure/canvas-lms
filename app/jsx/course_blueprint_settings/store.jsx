import { createStore, applyMiddleware } from 'redux'
import ReduxThunk from 'redux-thunk'
import ReduxLogger from 'redux-logger'
import rootReducer from './reducer'

  const logger = ReduxLogger()

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk,
    logger
  )(createStore)

  export default function configStore (initialState) {
    return createStoreWithMiddleware(rootReducer, initialState)
  }
