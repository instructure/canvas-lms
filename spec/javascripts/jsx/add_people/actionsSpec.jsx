define([
  'axios',
  'jsx/add_people/store',
  'jsx/add_people/api-client',
  'jsx/add_people/actions',
], (axios, createStore, api, { actions, actionTypes }) => {
  // mock axios
  let sandbox = null

  const mockAxios = (adapter) => {
    restoreAxios()
    sandbox = sinon.sandbox.create()
    sandbox.stub(axios, 'post', adapter)
  }

  const restoreAxios = () => {
    if (sandbox) sandbox.restore()
    sandbox = null
  }

  const mockAxiosSuccess = (data = {}) => {
    mockAxios(() => Promise.resolve({ data, status: 200, statusText: 'Ok', headers: {} }))
  }

  const mockAxiosFail = (err = { message: 'Error' }) => {
    mockAxios(() => Promise.reject({ message: err.message, response: { data: err, status: 400, statusText: 'Bad Request', headers: {} } }))
  }

  // mock a store
  let store = null
  let storeSpy = null

  const mockStore = (state = {}) => {
    storeSpy = sinon.spy()
    store = createStore((state, action) => {
      storeSpy(action)
      return state
    }, state)
  }

  const testConfig = () => ({
    setup () {
      mockStore()
    },
    teardown () {
      restoreAxios()
    }
  })

  module('Add People Actions', () => {
    module('validateUsers', testConfig())

    test('dispatches START when called', () => {
      store.dispatch(actions.validateUsers([]))
      ok(storeSpy.withArgs({ type: actionTypes.VALIDATE_USERS_START }).calledOnce)
    })

    test('dispatches SUCCESS with data when successful', (assert) => {
      const resolved = assert.async()

      mockAxiosSuccess({ data: 'foo' })
      store.dispatch(actions.validateUsers([]))

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.VALIDATE_USERS_SUCCESS, payload: { data: 'foo' } }).calledOnce)
        resolved()
      }, 1)
    })

    test('dispatches ERROR with error when fails', (assert) => {
      const resolved = assert.async()

      mockAxiosFail({ message: 'an error occurred' })
      store.dispatch(actions.validateUsers([]))

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.VALIDATE_USERS_ERROR, payload: { message: 'an error occurred' } }).calledOnce)
        resolved()
      }, 1)
    })

    module('createUsers', testConfig())

    test('dispatches START when called', () => {
      store.dispatch(actions.createUsers([]))
      ok(storeSpy.withArgs({ type: actionTypes.CREATE_USERS_START }).calledOnce)
    })

    test('dispatches SUCCESS with data when successful', (assert) => {
      const resolved = assert.async()

      mockAxiosSuccess({ data: 'foo' })
      store.dispatch(actions.createUsers([]))

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.CREATE_USERS_SUCCESS, payload: { data: 'foo' } }).calledOnce)
        resolved()
      }, 1)
    })

    test('dispatches ERROR with error when fails', (assert) => {
      const resolved = assert.async()

      mockAxiosFail({ message: 'an error occurred' })
      store.dispatch(actions.createUsers([]))

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.CREATE_USERS_ERROR, payload: { message: 'an error occurred' } }).calledOnce)
        resolved()
      }, 1)
    })

    module('enrollUsers', testConfig())

    test('dispatches START when called', () => {
      store.dispatch(actions.enrollUsers([]))
      ok(storeSpy.withArgs({ type: actionTypes.ENROLL_USERS_START }).calledOnce)
    })

    test('dispatches SUCCESS with data when successful', (assert) => {
      const resolved = assert.async()

      mockAxiosSuccess({ data: 'foo' })
      store.dispatch(actions.enrollUsers([]))


      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.ENROLL_USERS_SUCCESS, payload: { data: 'foo' } }).calledOnce)
        resolved()
      }, 1)
    })

    test('dispatches ERROR with error when fails', (assert) => {
      const resolved = assert.async()

      mockAxiosFail({ message: 'an error occurred' })
      store.dispatch(actions.enrollUsers([]))

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.ENROLL_USERS_ERROR, payload: { message: 'an error occurred' } }).calledOnce)
        resolved()
      }, 1)
    })
  })
})
