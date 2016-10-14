define([
  'axios',
], (axios) => {
  const CyoeClient = {
    call ({ apiUrl, jwt }, path) {
      return axios({
        url: apiUrl + path,
        dataType: 'json',
        headers: {
          Authorization: 'Bearer ' + jwt,
        },
      })
      .then(res => res.data)
    },

    loadInitialData (state) {
      const path = `/students_per_range?trigger_assignment=${state.assignment.id}`
      return CyoeClient.call(state, path)
    },

    loadStudent (state, studentId) {
      const path = `/student_details?trigger_assignment=${state.assignment.id}&student_id=${studentId}`
      return CyoeClient.call(state, path)
    },
  }

  return CyoeClient
})
