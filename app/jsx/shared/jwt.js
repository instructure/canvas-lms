import axios from 'axios'

export function refreshFn (initialToken) {
  let token = initialToken
  let promise = null

  return (done) => {
    if (promise === null) {
      promise = axios
        .post('/api/v1/jwts/refresh', { jwt: token })
        .then((resp) => {
          promise = null
          token = resp.data.token
          return token
        })
    }

    if (typeof done === 'function') {
      promise.then(done)
    }

    return promise
  }
}
