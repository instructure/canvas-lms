define([
  'axios',
  'jsx/shared/helpers/parseLinkHeader',
], (axios, parseLinkHeader) => {
  const ApiClient = {
    _depaginate (url, allResults = []) {
      return axios.get(url)
        .then((res) => {
          const results = allResults.concat(res.data)
          if (res.headers.link) {
            const links = parseLinkHeader(res)
            if (links.next) {
              return this._depaginate(links.next, results)
            }
          }
          res.data = results
          return res
        })
    },

    _queryString (params) {
      return params.map((param) => {
        const key = Object.keys(param)[0]
        const value = param[key]
        return value ? `${key}=${value}` : null
      }).filter(param => !!param).join('&')
    },

    getCourses ({ accountId }, { search = '', term = '', subAccount = '' } = {}) {
      const params = this._queryString([
        { per_page: '100' },
        { blueprint: 'false' },
        { blueprint_associated: 'false' },
        { 'include[]': 'term' },
        { 'include[]': 'teachers' },
        { search_term: search },
        { enrollment_term_id: term },
      ])

      return this._depaginate(`/api/v1/accounts/${subAccount || accountId}/courses?${params}`)
    },

    getAssociations ({ course }) {
      const params = this._queryString([
        { per_page: '100' },
      ])

      return this._depaginate(`/api/v1/courses/${course.id}/blueprint_templates/default/associated_courses?${params}`)
    },

    saveAssociations ({ course, addedAssociations, removedAssociations }) {
      return axios.put(`/api/v1/courses/${course.id}/blueprint_templates/default/update_associations`, {
        course_ids_to_add: addedAssociations.map(c => c.id),
        course_ids_to_remove: removedAssociations,
      })
    }
  }

  return ApiClient
})
