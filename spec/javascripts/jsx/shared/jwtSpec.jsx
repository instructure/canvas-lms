define(['jsx/shared/jwt', 'axios'], (jwt, axios) => {
  let thenStub
  let promise
  let token
  let newToken
  let refreshFn

  QUnit.module('Jwt refreshFn', {
    setup() {
      token = 'testjwt'
      newToken = 'newtoken'
      promise = Promise.resolve(newToken)
      sinon.spy(promise, 'then')
      thenStub = sinon.stub().returns(promise)
      this.stub(axios, 'post').returns({then: thenStub})
      refreshFn = jwt.refreshFn(token)
    }
  })

  test('posts token to refresh endpoint', () => {
    refreshFn()
    ok(axios.post.calledWithMatch('/api/v1/jwts/refresh', {jwt: token}))
  })

  test('only posts once if called multiple times before response', () => {
    refreshFn()
    refreshFn()
    equal(axios.post.callCount, 1)
  })

  test('returns promise resolved after request', () => {
    equal(refreshFn(), promise)
  })

  test('calls callbacks with new token', () => {
    const spy = sinon.spy()
    refreshFn(spy)
    ok(promise.then.calledWith(spy))
  })

  test('gets token from response data', () => {
    refreshFn()
    equal(thenStub.firstCall.args[0]({data: {token: newToken}}), newToken)
  })

  test('updates token in closure', () => {
    refreshFn()
    thenStub.firstCall.args[0]({data: {token: newToken}})
    refreshFn()
    ok(axios.post.calledWithMatch('/api/v1/jwts/refresh', {jwt: newToken}))
  })
})
