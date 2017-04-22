import { createStore, applyMiddleware } from 'redux'
import ReduxThunk from 'redux-thunk'
import ReduxLogger from 'redux-logger'
import reducer from '../reducer'
import initialState from './initialState'

const logger = ReduxLogger();

const createStoreWithMiddleware = applyMiddleware(
  logger,
  ReduxThunk
)(createStore);

function configureStore (state = initialState) {
  return createStoreWithMiddleware(reducer, state);
};

export default configureStore
