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
      return state;
    },
    SET_COURSE_IMAGE_ID (state, action) {
      state.imageUrl = action.payload.imageUrl;
      state.courseImage = action.payload.imageId;
      state.showModal = false;
      state.hiddenInputName = "course[image_id]"
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