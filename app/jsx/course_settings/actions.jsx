define ([
  "axios"
], (axios) => {

  const Actions = {

    gotCourseImage (imageUrl) {
      return {
        type: 'GOT_COURSE_IMAGE',
        payload: {
          imageUrl
        }
      };
    },

    setModalVisibility (showModal) {
      return {
        type: 'MODAL_VISIBILITY',
        payload: {
          showModal
        }
      };
    },

    getCourseImage (courseId, ajaxLib = axios) {
      return (dispatch, getState) => {
        ajaxLib.get(`/api/v1/courses/${courseId}/settings`)
               .then((response) => {
                  dispatch(this.gotCourseImage(response.data.image, courseId));
                })
               .catch((response) => {
                  console.error('There is an error');
                });
      };
    }
  };

  return Actions;
});