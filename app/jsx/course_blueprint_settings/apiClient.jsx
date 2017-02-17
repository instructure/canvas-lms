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

    getCourses ({ accountId }, { search = '', term = '', subAccount = '' } = {}) {
      const params = [
        { per_page: '100' },
        { blueprint: 'false' },
        { blueprint_associated: 'false' },
        { 'include[]': 'term' },
        { 'include[]': 'teachers' },
        { search_term: search },
        { enrollment_term_id: term },
      ].map((param) => {
        const key = Object.keys(param)[0]
        const value = param[key]
        return value ? `${key}=${value}` : null
      }).filter(param => !!param).join('&')

      return this._depaginate(`/api/v1/accounts/${subAccount || accountId}/courses?${params}`)
    },
  }

  return ApiClient
})
