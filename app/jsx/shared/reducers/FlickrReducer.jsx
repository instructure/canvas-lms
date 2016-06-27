  define([
  '../stores/FlickrInitialState',
  'underscore'
], (FlickrInitialState, _) => {

  const flickrHandlers = {
    START_FLICKR_SEARCH (state, action) {
      state.page = action.page;
      state.searchTerm = action.term;
      return state;
    },
    RECEIVE_FLICKR_RESULTS (state, action) {
      state.searchResults = action.results;
      return state;
    },
    CLEAR_FLICKR_SEARCH (state) {
      state.searchResults = [];
      state.page = 1;
      state.searchTerm = '';
      return state;
    },
    FAIL_FLICKR_SEARCH (state, action) {
      state.searchResults = [];
      return state;
    }
  };

  const flickr = (state = FlickrInitialState, action) => { 
    if (flickrHandlers[action.type]) {
      const newState = _.extend({}, state);
      return flickrHandlers[action.type](newState, action);
    } 
    else {
      return state;
    }
  };

  return flickr;

});