define([
  'axios',
], (axios) => ({
  /*
    @param users: array of user ids
    @param searchType: one of ['unique_id', 'sis_user_id', 'cc_path']
    @returns {
      duplicates: [{ }] -- multiple matches found
      users: [{ account_id, account_name, address, user_id, user_name }] -- single match found
      missing: [{ address, type }] -- no user match found
      error: [{ message }]
    }
  */
  validateUsers ({ courseId }, users, searchType = 'unique_id') {
    return axios.post(`/courses/${courseId}/user_lists.json`, { user_list: users, v2: true, search_type: searchType })
  },

  /*
    @param users: array of user objects, email is req [{ email, name }]
    @returns {
      invited_users:  [{ email, id }] -- successfully created users
      errored_users:  [{ email, errors[{ message }] }] -- bad & already existing users end up in here
    }
  */
  createUsers ({ courseId }, users) {
    return axios.post(`/courses/${courseId}/invite_users`, { users })
  },

  /*
    @param users: array of user ids
  */
  enrollUsers ({ courseId }, users, role = 'student', section) {
    return axios.post(`/courses/${courseId}/enroll_users`, { users_ids: users, role })
  },
}))
