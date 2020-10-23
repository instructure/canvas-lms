/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import assert from 'assert'
import * as actions from '../../../src/sidebar/actions/data'
import sinon from 'sinon'
import {spiedStore} from './utils'

describe('Sidebar data actions', () => {
  // collection key to use in testing
  const collectionKey = 'theCollection'
  const searchString = 'search-string'
  const uriFor = () => 'bookmark'

  // trivial "always succeeds" source
  const successPage = {links: 'successLinks', bookmark: 'successBookmark'}
  const successSource = {
    fetchPage() {
      return new Promise(resolve => {
        resolve(successPage)
      })
    },
    uriFor
  }

  // trivial "always fails" source
  const brokenError = new Error('broken')
  const brokenSource = {
    fetchPage() {
      return new Promise(() => {
        throw brokenError
      })
    },
    uriFor
  }

  // returns a "black hole" source that spies fetchPage
  function stubbedSource() {
    return {
      fetchPage: sinon.stub().returns(new Promise(() => {})),
      uriFor: sinon.stub().returns('bookmark')
    }
  }

  // constants for testing that can be overridden in props to storeState (see
  // below)
  const defaults = {
    jwt: 'theJWT',
    source: successSource,
    links: [],
    bookmark: 'bookmark',
    loading: false,
    searchString: ''
  }

  // defaults and reshapes the given props into the shape needed by the store
  function setupState(props) {
    const {jwt, source, links, bookmark, loading} = {
      ...defaults,
      ...props
    }
    const collection = {links, bookmark, loading}
    const collections = {[collectionKey]: collection}
    return {jwt, source, collections}
  }

  describe('fetchPage', () => {
    it('dispatches requestPage first', () => {
      const store = spiedStore(setupState())
      store.dispatch(actions.fetchPage(collectionKey, searchString))
      const callArgs = store.spy.getCall(1).args[0]
      assert.strictEqual(callArgs.type, actions.REQUEST_PAGE)
      assert.strictEqual(callArgs.key, collectionKey)
      assert.strictEqual(callArgs.searchString, searchString)
    })

    it('uses bookmark from store to call source.fetchPage', () => {
      const source = stubbedSource()
      const state = setupState({source})
      const store = spiedStore(state)
      store.dispatch(actions.fetchPage(collectionKey, searchString))
      sinon.assert.calledWith(source.fetchPage, defaults.bookmark)
    })

    it('dispatches receivePage with page retrieved from source', done => {
      const store = spiedStore(setupState())
      store
        .dispatch(actions.fetchPage(collectionKey, searchString))
        .then(() => {
          const callArgs = store.spy.lastCall.args[0]
          assert.strictEqual(callArgs.type, actions.RECEIVE_PAGE)
          assert.strictEqual(callArgs.key, collectionKey)
          assert.strictEqual(callArgs.links, successPage.links)
          assert.strictEqual(callArgs.bookmark, successPage.bookmark)
          done()
        })
        .catch(done)
    })

    it('dispatches failPage on error retrieving page from source', done => {
      const store = spiedStore(setupState({source: brokenSource}))
      store
        .dispatch(actions.fetchPage(collectionKey, searchString))
        .then(() => {
          const callArgs = store.spy.lastCall.args[0]
          assert.strictEqual(callArgs.type, actions.FAIL_PAGE)
          assert.strictEqual(callArgs.key, collectionKey)
          assert.strictEqual(callArgs.error, brokenError)
          done()
        })
        .catch(done)
    })
  })

  describe('fetchNextPage', () => {
    it('fetches next page if collection has bookmark and is not loading', () => {
      const store = spiedStore(setupState())
      store.dispatch(actions.fetchNextPage(collectionKey, undefined))
      sinon.assert.calledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        key: collectionKey,
        searchString: undefined
      })
    })

    it('skips fetching next page if collection has no bookmark', () => {
      const source = {...successSource, uriFor: () => null}
      const store = spiedStore(setupState({bookmark: null, source}))
      store.dispatch(actions.fetchNextPage(collectionKey, undefined))
      sinon.assert.neverCalledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        key: collectionKey,
        searchString: undefined
      })
    })

    it('skips fetching next page if collection is already loading', () => {
      const store = spiedStore(setupState({loading: true}))
      store.dispatch(actions.fetchNextPage(collectionKey, searchString))
      sinon.assert.neverCalledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        key: collectionKey,
        searchString
      })
    })
  })

  describe('fetchInitialPage', () => {
    it('fetches initial page if collection is empty, has bookmark, and is not loading', () => {
      const store = spiedStore(setupState())
      store.dispatch(actions.fetchInitialPage(collectionKey, undefined))
      sinon.assert.calledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        key: collectionKey,
        searchString: undefined
      })
    })

    it('skips fetching initial page if collection is not empty', () => {
      const store = spiedStore(setupState({links: [{href: 'link', title: 'A Link'}]}))
      store.dispatch(actions.fetchInitialPage(collectionKey, undefined))
      sinon.assert.neverCalledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        key: collectionKey,
        searchString: undefined
      })
    })

    it('skips fetching initial page if collection has no bookmark', () => {
      const store = spiedStore(setupState({bookmark: null}))
      store.dispatch(actions.fetchInitialPage(collectionKey, undefined))
      sinon.assert.neverCalledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        key: collectionKey,
        searchString
      })
    })

    it('skips fetching initial page if collection is already loading', () => {
      const store = spiedStore(setupState({loading: true}))
      store.dispatch(actions.fetchInitialPage(collectionKey, undefined))
      sinon.assert.neverCalledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        key: collectionKey,
        searchString
      })
    })

    it('fetches initial page if searchString changes', () => {
      const store = spiedStore(setupState())
      store.dispatch(actions.fetchNextPage(collectionKey, searchString))
      sinon.assert.calledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        key: collectionKey,
        searchString
      })
    })
  })
})
