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
    UPLOADING_IMAGE (state, action) {
      state.uploadingImage = true;
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
      state.uploadingImage = false;
      return state;
    },
    SET_COURSE_IMAGE_URL (state, action) {
      state.imageUrl = action.payload.imageUrl;
      state.courseImage = action.payload.imageUrl;
      state.showModal = false;
      state.uploadingImage = false;
      return state;
    },
    ERROR_UPLOADING_IMAGE (state) {
      state.uploadingImage = false;
      return state;
    },
    REMOVING_IMAGE (state) {
      state.removingImage = true;
      return state;
    },
    REMOVED_IMAGE (state) {
      state.imageUrl = '';
      state.courseImage = 'abc';
      state.removingImage = false;
      return state;
    },
    ERROR_REMOVING_IMAGE (state) {
      state.removingImage = false;
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