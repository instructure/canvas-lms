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
import RceApiSource from '../../../src/rcs/api'
import sinon from 'sinon'
import {spiedStore} from './utils'

describe('Sidebar data actions', () => {
  // collection key to use in testing
  const collectionKey = 'theCollection'
  const searchString = 'search-string'
  const uriFor = () => 'uriFor/bookmark'

  // trivial "always succeeds" source
  const successPage = {links: 'successLinks', bookmark: 'successBookmark'}
  const successSource = {
    fetchLinks(key) {
      return this.fetchPage(key)
    },
    fetchPage(_uri) {
      return new Promise(resolve => {
        resolve(successPage)
      })
    },
    uriFor
  }

  // trivial "always fails" source
  const brokenError = new Error('broken')
  const brokenSource = {
    fetchLinks(key) {
      return this.fetchPage(key)
    },
    fetchPage(_uri) {
      return new Promise(() => {
        throw brokenError
      })
    },
    uriFor
  }

  // returns a "black hole" source that spies fetchLinks
  function stubbedSource() {
    const source = new RceApiSource()
    sinon.stub(source, 'fetchPage').returns(new Promise(resolve => resolve(successPage)))
    sinon.stub(source, 'uriFor').returns('uriFor/bookmark')
    return source
  }

  // constants for testing that can be overridden in props to storeState (see
  // below)
  const defaultCollection = {
    links: [],
    bookmark: 'bookmark',
    isLoading: false,
    searchString
  }
  const defaults = {
    jwt: 'theJWT',
    source: successSource,
    searchString,
    collections: {
      [`${collectionKey}`]: defaultCollection
    }
  }

  // defaults and reshapes the given props into the shape needed by the store
  function setupState(props = {}, collectionProps = {}) {
    const retval = {...defaults, ...props}
    const collection = {...defaultCollection, ...collectionProps}
    retval.collections[collectionKey] = collection
    return retval
  }

  describe('fetchPage', () => {
    it('uses bookmark from store to call source.fetchPage', () => {
      const source = stubbedSource()
      const state = setupState({source})
      const store = spiedStore(state)
      store.dispatch(actions.fetchPage(collectionKey))
      sinon.assert.calledWith(source.fetchPage, defaultCollection.bookmark)
    })

    it('dispatches receivePage with page retrieved from source', done => {
      const store = spiedStore(setupState())
      store
        .dispatch(actions.fetchPage(collectionKey))
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
        .dispatch(actions.fetchPage(collectionKey))
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
    it('dispatches requestPage first', () => {
      const store = spiedStore(setupState())
      store.dispatch(actions.fetchNextPage(collectionKey))
      const callArgs = store.spy.getCall(1).args[0]
      assert.strictEqual(callArgs.type, actions.REQUEST_PAGE)
      assert.strictEqual(callArgs.key, collectionKey)
    })

    it('fetches next page if collection has bookmark and is not loading', () => {
      const store = spiedStore(setupState())
      store.dispatch(actions.fetchNextPage(collectionKey))
      sinon.assert.calledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        cancel: sinon.match.func,
        key: collectionKey
      })
    })

    it('cancels previous fetch if collection is already loading', () => {
      const cancel = sinon.spy()
      const store = spiedStore(setupState({}, {isLoading: true, cancel}))
      store.dispatch(actions.fetchNextPage(collectionKey))

      sinon.assert.called(cancel)

      sinon.assert.calledWith(store.spy, {
        type: actions.REQUEST_PAGE,
        cancel: sinon.match.func,
        key: collectionKey
      })
    })
  })

  describe('fetchInitialPage', () => {
    it('fetches initial page if collection is empty, has bookmark, and is not loading', () => {
      const store = spiedStore(setupState())
      store.dispatch(actions.fetchInitialPage(collectionKey))
      sinon.assert.calledWith(store.spy, {
        type: actions.REQUEST_INITIAL_PAGE,
        cancel: sinon.match.func,
        key: collectionKey,
        searchString
      })
    })

    it('skips fetching initial page if collection is not empty', () => {
      const store = spiedStore(setupState({}, {links: [{href: 'link', title: 'A Link'}]}))
      store.dispatch(actions.fetchInitialPage(collectionKey))
      sinon.assert.neverCalledWith(store.spy, {
        type: actions.REQUEST_INITIAL_PAGE,
        cancel: sinon.match.func,
        key: collectionKey,
        searchString
      })
    })

    it('creates the URL if collection has no bookmark', () => {
      const source = stubbedSource()
      const store = spiedStore(setupState({source}, {bookmark: null}))
      store.dispatch(actions.fetchInitialPage(collectionKey))
      sinon.assert.calledWith(source.fetchPage, 'uriFor/bookmark')
    })

    it('cancels previous fetch if collection is already loading', () => {
      const cancel = sinon.spy()
      const store = spiedStore(setupState({}, {isLoading: true, cancel}))
      store.dispatch(actions.fetchInitialPage(collectionKey))

      sinon.assert.called(cancel)

      sinon.assert.calledWith(store.spy, {
        type: actions.REQUEST_INITIAL_PAGE,
        cancel: sinon.match.func,
        key: collectionKey,
        searchString
      })
    })
  })
})
