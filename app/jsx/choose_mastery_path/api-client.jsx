define([
  'axios',
], (axios) => {
  const ApiClient = {
    selectOption ({ courseId, moduleId, itemId }, option) {
      return axios({
        method: 'post',
        url: `/api/v1/courses/${courseId}/modules/${moduleId}/items/${itemId}/select_mastery_path`,
        data: {
          assignment_set_id: option,
        },
      })
    },
  }

  return ApiClient
})
