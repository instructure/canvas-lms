/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute test and/or modify test under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that test will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {createGradebook} from 'jsx/gradebook/default_gradebook/__tests__/GradebookSpecHelper'
import ContextModulesLoader from 'jsx/gradebook/default_gradebook/DataLoader/ContextModulesLoader'
import {NetworkFake, setPaginationLinkHeader} from 'jsx/shared/network/NetworkFake'
import {RequestDispatch} from 'jsx/shared/network'

/* eslint-disable no-async-promise-executor */
QUnit.module('Gradebook > DataLoader > ContextModulesLoader', suiteHooks => {
  const url = '/api/v1/courses/1201/modules'

  let dataLoader
  let dispatch
  let exampleData
  let gradebook
  let network

  suiteHooks.beforeEach(() => {
    exampleData = {
      contextModules: [{id: '2601'}, {id: '2602 '}, {id: '2603'}]
    }
  })

  QUnit.module('#loadContextModules()', hooks => {
    hooks.beforeEach(() => {
      network = new NetworkFake()
      dispatch = new RequestDispatch()

      gradebook = createGradebook({
        context_id: '1201'
      })
      sinon.stub(gradebook, 'updateContextModules')

      dataLoader = new ContextModulesLoader({dispatch, gradebook})
    })

    hooks.afterEach(() => {
      network.restore()
    })

    function loadContextModules() {
      return dataLoader.loadContextModules()
    }

    function getRequests() {
      return network.getRequests(request => request.path === url)
    }

    test('sends a request to the context modules url', async () => {
      loadContextModules()
      await network.allRequestsReady()
      const requests = getRequests()
      strictEqual(requests.length, 1)
    })

    QUnit.module('when the first page resolves', contextHooks => {
      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          loadContextModules()
          await network.allRequestsReady()
          const [{response}] = getRequests()
          setPaginationLinkHeader(response, {last: 3})
          response.setJson(exampleData.contextModules.slice(0, 1))
          response.send()
          await network.allRequestsReady()
          resolve()
        })
      })

      test('sends a request for each additional page', () => {
        const pages = getRequests()
          .slice(1)
          .map(request => request.params.page)
        deepEqual(pages, ['2', '3'])
      })

      test('uses the same path for each page', () => {
        const [{path}] = getRequests()
        getRequests()
          .slice(1)
          .forEach(request => {
            equal(request.path, path)
          })
      })

      test('uses the same parameters for each page', () => {
        const [{params}] = getRequests()
        getRequests()
          .slice(1)
          .forEach(request => {
            const {page, ...pageParams} = request.params
            deepEqual(pageParams, params)
          })
      })
    })

    QUnit.module('when all pages have resolved', contextHooks => {
      let contextModulesLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          contextModulesLoaded = loadContextModules()
          await network.allRequestsReady()

          // Resolve the first page
          const [{response}] = getRequests()
          setPaginationLinkHeader(response, {last: 3})
          response.setJson(exampleData.contextModules.slice(0, 1))
          response.send()
          await network.allRequestsReady()

          // Resolve the remaining pages
          const [request2, request3] = getRequests().slice(1)
          setPaginationLinkHeader(request2.response, {last: 3})
          request2.response.setJson(exampleData.contextModules.slice(1, 2))
          request2.response.send()

          setPaginationLinkHeader(request3.response, {last: 3})
          request3.response.setJson(exampleData.contextModules.slice(2, 3))
          request3.response.send()

          resolve()
        })
      })

      test('updates the context modules in the gradebook', async () => {
        strictEqual(gradebook.updateContextModules.callCount, 1)
      })

      test('includes the loaded context modules when updating the gradebook', async () => {
        const [contextModules] = gradebook.updateContextModules.lastCall.args
        deepEqual(contextModules, exampleData.contextModules)
      })

      test('resolves the returned promise', async () => {
        equal(await contextModulesLoaded, null)
      })

      test('resolves the returned promise after updating the gradebook', () => {
        return contextModulesLoaded.then(() => {
          strictEqual(gradebook.updateContextModules.callCount, 1)
        })
      })
    })

    QUnit.module('if the first response does not link to the last page', contextHooks => {
      /*
       * This supposes that somehow the pagination links are either not present
       * or have excluded the last page, which is required for pagination
       * cheating to work for Gradebook. /
       */

      let contextModulesLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          contextModulesLoaded = loadContextModules()
          await network.allRequestsReady()
          const [{response}] = getRequests()
          response.setJson(exampleData.contextModules.slice(0, 1))
          response.send()
          await network.allRequestsReady()
          resolve()
        })
      })

      test('does not send additional requests', () => {
        strictEqual(getRequests().length, 1)
      })

      test('resolves the returned promise', async () => {
        equal(await contextModulesLoaded, null)
      })
    })
  })
})
/* eslint-enable no-async-promise-executor */
