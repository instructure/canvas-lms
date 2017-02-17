define([
  'axios',
  'jsx/add_people/store',
  'jsx/add_people/api_client',
  'jsx/add_people/actions',
  './initialState'
], (axios, {createStore}, api, { actions, actionTypes }, INITIAL_STATE) => {
  // mock axios
  let sandbox = null

  const restoreAxios = () => {
    if (sandbox) sandbox.restore()
    sandbox = null
  }

  const mockAxios = (adapter) => {
    restoreAxios()
    sandbox = sinon.sandbox.create()
    sandbox.stub(axios, 'post').callsFake(adapter)
  }

  const mockAxiosSuccess = (data = {}) => {
    mockAxios(() => Promise.resolve({ data, status: 200, statusText: 'Ok', headers: {} }))
  }

  const failureData = { message: 'Error', response: { data: 'Error', status: 400, statusText: 'Bad Request', headers: {} } };
  const mockAxiosFail = () => {
    mockAxios(() => Promise.reject(failureData));
  }

  // mock a store
  let store = null
  let storeSpy = null
  let runningState = INITIAL_STATE;

  const mockStore = (state = runningState) => {
    storeSpy = sinon.spy()
    store = createStore((st, action) => {
      storeSpy(action)
      return st
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

  QUnit.module('Add People Actions', () => {
    QUnit.module('validateUsers', testConfig())

    test('dispatches VALIDATE_USERS_START when called', () => {
      mockAxiosSuccess();
      store.dispatch(actions.validateUsers())
      ok(storeSpy.withArgs({ type: actionTypes.VALIDATE_USERS_START }).calledOnce);
    })

    test('dispatches VALIDATE_USERS_SUCCESS with data when successful', (assert) => {
      const resolved = assert.async();
      const apiResponse = { users: [], duplicates: [], missing: [], errors: [] };

      mockAxiosSuccess(apiResponse);
      store.dispatch(actions.validateUsers());

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.VALIDATE_USERS_SUCCESS, payload: apiResponse }).calledOnce);
        resolved();
      }, 1)
    })

    test('dispatches ENQUEUE_USERS_TO_BE_ENROLLED with data when validate users returns no dupes or missings', (assert) => {
      const resolved = assert.async();
      const apiResponse = {
        users: [
          {
            address: 'auser@example.com',
            user_id: 2,
            user_name: 'A User',
            account_id: 1,
            account_name: 'The Account',
            email: 'auser@example.com'
          }
        ],
        duplicates: [],
        missing: [],
        errors: [] };

      mockAxiosSuccess(apiResponse);
      store.dispatch(actions.validateUsers());

      setTimeout(() => {
        ok(storeSpy.withArgs(sinon.match({ type: actionTypes.ENQUEUE_USERS_TO_BE_ENROLLED})).calledOnce);
        resolved();
      }, 1)
    })

    test('dispatches VALIDATE_USERS_ERROR with error when fails', (assert) => {
      const resolved = assert.async()

      mockAxiosFail()
      store.dispatch(actions.validateUsers())

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.VALIDATE_USERS_ERROR, payload: failureData }).calledOnce)
        resolved()
      }, 1)
    })

    QUnit.module('resolveValidationIssues', testConfig())

    test('dispatches CREATE_USERS_START when called', () => {
      mockAxiosSuccess();
      store.dispatch(actions.resolveValidationIssues())
      ok(storeSpy.withArgs({ type: actionTypes.CREATE_USERS_START }).calledOnce)
    })

    test('dispatches CREATE_USERS_SUCCESS with data when successful', (assert) => {
      const newUser = {name: 'foo', email: 'foo@bar.com'};
      runningState.userValidationResult.duplicates = {foo: {createNew: true, newUserInfo: newUser}};
      const resolved = assert.async();
      const apiResponse = {invited_users: [newUser], errored_users: []};

      mockAxiosSuccess(apiResponse)
      store.dispatch(actions.resolveValidationIssues())

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.CREATE_USERS_SUCCESS, payload: apiResponse }).calledOnce)
        ok(storeSpy.withArgs({ type: actionTypes.ENQUEUE_USERS_TO_BE_ENROLLED, payload: [newUser]}))
        resolved()
      }, 1)
    })

    test('dispatches CREATE_USERS_ERROR with error when fails', (assert) => {
      const resolved = assert.async()

      mockAxiosFail()
      store.dispatch(actions.resolveValidationIssues())

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.CREATE_USERS_ERROR, payload: failureData }).calledOnce)
        resolved()
      }, 1)
    })

    QUnit.module('enrollUsers', testConfig())

    test('dispatches START when called', () => {
      mockAxiosSuccess();
      store.dispatch(actions.enrollUsers())
      ok(storeSpy.withArgs({ type: actionTypes.ENROLL_USERS_START }).calledOnce)
    })

    test('dispatches SUCCESS with data when successful', (assert) => {
      const resolved = assert.async()

      mockAxiosSuccess({ data: 'foo' })
      store.dispatch(actions.enrollUsers())


      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.ENROLL_USERS_SUCCESS, payload: { data: 'foo' } }).calledOnce)
        resolved()
      }, 1)
    })

    test('dispatches ERROR with error when fails', (assert) => {
      const resolved = assert.async()

      mockAxiosFail()
      store.dispatch(actions.enrollUsers())

      setTimeout(() => {
        ok(storeSpy.withArgs({ type: actionTypes.ENROLL_USERS_ERROR, payload: failureData }).calledOnce)
        resolved()
      }, 1)
    })

    QUnit.module('chooseDuplicate', testConfig())

    test('dispatches dependent actions', (/* assert */) => {
      runningState = INITIAL_STATE;
      runningState.userValidationResult.duplicates = {foo: {selectedUserId: 1, newUserInfo: {email: 'foo', name: 'bar'}}};

      store.dispatch(actions.chooseDuplicate({address: 'foo', user_id: 1}));

      ok(storeSpy.withArgs({ type: actionTypes.CHOOSE_DUPLICATE, payload: {address: 'foo', user_id: 1} }).calledOnce, 'CHOOSE_DUPLICATE');
    })

    QUnit.module('skipDuplicate', testConfig())

    test('dispatches dependent actions', (/* assert */) => {
      store.dispatch(actions.skipDuplicate({address: 'foo'}));

      ok(storeSpy.withArgs({ type: actionTypes.SKIP_DUPLICATE, payload: {address: 'foo'} }).calledOnce, 'SKIP_DUPLICATE');
    })

    QUnit.module('enqueue new ', testConfig())
    test('for duplicate dispatches dependent action', (/* assert */) => {
      const newUser = {name: 'Foo Bar', email: 'foo@bar.com'};

      store.dispatch(actions.enqueueNewForDuplicate({address: 'foo', newUserInfo: newUser}));

      ok(storeSpy.withArgs({
        type: actionTypes.ENQUEUE_NEW_FOR_DUPLICATE,
        payload: {address: 'foo', newUserInfo: newUser }
      }).calledOnce, 'ENQUEUE_NEW_FOR_DUPLICATE');
    })

    test('for missing dispatches dependent action', (/* assert */) => {
      const newUser = {name: 'Foo Bar', email: 'foo@bar.com'};
      runningState.userValidationResult.missing = {
        foo: {
          newUserInfo: newUser
        }
      };

      store.dispatch(actions.enqueueNewForMissing({address: 'foo', newUser}));

      ok(storeSpy.withArgs({
        type: actionTypes.ENQUEUE_NEW_FOR_MISSING,
        payload: {address: 'foo', newUser }
      }).calledOnce, 'ENQUEUE_NEW_FOR_MISSING');
    })
  })
});
