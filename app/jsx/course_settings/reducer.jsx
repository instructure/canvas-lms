define([
  './actions',
  './store/initialState',
  'underscore'
], (Actions, initialState, _) => {

  const courseImageHandlers = {
    MODAL_VISIBILITY (state, action) {
      state.showModal = action.payload.showModal;
      return state;
    },
    GOT_COURSE_IMAGE (state, action) {
      state.courseImage = action.payload.imageString;
      state.imageUrl = action.payload.imageUrl;
      state.gettingImage = false;
      return state;
    },
    SET_COURSE_IMAGE_ID (state, action) {
      state.imageUrl = action.payload.imageUrl;
      state.courseImage = action.payload.imageId;
      state.showModal = false;
      return state;
    },
    SET_COURSE_IMAGE_URL (state, action) {
      state.imageUrl = action.payload.imageUrl;
      state.courseImage = action.payload.imageUrl;
      state.showModal = false;
      return state;
    },
    REMOVE_IMAGE (state) {
      state.imageUrl = '';
      state.courseImage = 'abc';
      return state;
    }
  };

  const courseImage = (state = initialState, action) => {
    if (courseImageHandlers[action.type]) {
      const newState = _.extend({}, state);
      return courseImageHandlers[action.type](newState, action);
    } else {
      return state;
    }
  };

  return courseImage;

});