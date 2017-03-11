define([
  './createStore',
], (createStore) => {
  const CoursesStore = createStore({
    getUrl () {
      return `/api/v1/accounts/${this.context.accountId}/courses`;
    },

    normalizeParams (params) {
      const payload = {}
      if (params.enrollment_term_id) payload.enrollment_term_id = params.enrollment_term_id
      if (params.search_term) payload.search_term = params.search_term
      if (params.with_students) payload.enrollment_type = ['student']
      payload.include = ['total_students', 'teachers']
      return payload
    }
  })

  return CoursesStore
})
