import { createStore, applyMiddleware } from 'redux'
import ReduxThunk from 'redux-thunk'
import FlickrReducer from '../reducers/FlickrReducer'
import FlickrInitialState from './FlickrInitialState'

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore);

export default createStoreWithMiddleware(FlickrReducer, FlickrInitialState)
