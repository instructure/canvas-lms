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

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper.js'
import CustomColumnsLoader from 'ui/features/gradebook/react/default_gradebook/DataLoader/CustomColumnsLoader.js'
import PerformanceControls from 'ui/features/gradebook/react/default_gradebook/PerformanceControls.js'
import {NetworkFake, setPaginationLinkHeader} from '@canvas/network/NetworkFake/index'
import {RequestDispatch} from '@canvas/network'

/* eslint-disable no-async-promise-executor */
QUnit.module('Gradebook > DataLoader > CustomColumnsLoader', suiteHooks => {
  const url = '/api/v1/courses/1201/custom_gradebook_columns'

  let dispatch
  let exampleData
  let gradebook
  let network
  let performanceControls

  suiteHooks.beforeEach(() => {
    exampleData = {
      customColumns: [
        {id: '2401', teacher_notes: true, hidden: true, title: 'Notes'},
        {id: '2402', teacher_notes: false, hidden: false, title: 'Other Notes'},
        {id: '2403', teacher_notes: false, hidden: false, title: 'Next Steps'}
      ]
    }
  })

  QUnit.module('#loadCustomColumns()', hooks => {
    hooks.beforeEach(() => {
      network = new NetworkFake()
      dispatch = new RequestDispatch()
      performanceControls = new PerformanceControls()

      gradebook = createGradebook({
        context_id: '1201'
      })
      sinon.stub(gradebook, 'gotCustomColumns')
    })

    hooks.afterEach(() => {
      network.restore()
    })

    function loadCustomColumns() {
      const dataLoader = new CustomColumnsLoader({dispatch, gradebook, performanceControls})
      return dataLoader.loadCustomColumns()
    }

    function getRequests() {
      return network.getRequests(request => request.path === url)
    }

    test('sends a request to the custom columns url', async () => {
      loadCustomColumns()
      await network.allRequestsReady()
      const requests = getRequests()
      strictEqual(requests.length, 1)
    })

    QUnit.module('when sending the initial request', () => {
      test('sets the `include_hidden` parameter to `true`', async () => {
        loadCustomColumns()
        await network.allRequestsReady()
        const [{params}] = getRequests()
        strictEqual(params.include_hidden, 'true')
      })

      test('sets the `per_page` parameter to the configured per page maximum', async () => {
        performanceControls = new PerformanceControls({customColumnsPerPage: 45})
        loadCustomColumns()
        await network.allRequestsReady()
        const [{params}] = getRequests()
        strictEqual(params.per_page, '45')
      })
    })

    QUnit.module('when the first page resolves', contextHooks => {
      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          loadCustomColumns()
          await network.allRequestsReady()
          const [{response}] = getRequests()
          setPaginationLinkHeader(response, {last: 3})
          response.setJson(exampleData.customColumns.slice(0, 1))
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
      let customColumnsLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          customColumnsLoaded = loadCustomColumns()
          await network.allRequestsReady()

          // Resolve the first page
          const [{response}] = getRequests()
          setPaginationLinkHeader(response, {last: 3})
          response.setJson(exampleData.customColumns.slice(0, 1))
          response.send()
          await network.allRequestsReady()

          // Resolve the remaining pages
          const [request2, request3] = getRequests().slice(1)
          setPaginationLinkHeader(request2.response, {last: 3})
          request2.response.setJson(exampleData.customColumns.slice(1, 2))
          request2.response.send()

          setPaginationLinkHeader(request3.response, {last: 3})
          request3.response.setJson(exampleData.customColumns.slice(2, 3))
          request3.response.send()

          resolve()
        })
      })

      test('updates the custom columns in the gradebook', async () => {
        strictEqual(gradebook.gotCustomColumns.callCount, 1)
      })

      test('includes the loaded custom columns when updating the gradebook', async () => {
        const [customColumns] = gradebook.gotCustomColumns.lastCall.args
        deepEqual(customColumns, exampleData.customColumns)
      })

      test('resolves the returned promise', async () => {
        equal(await customColumnsLoaded, null)
      })

      test('resolves the returned promise after updating the gradebook', () => {
        return customColumnsLoaded.then(() => {
          strictEqual(gradebook.gotCustomColumns.callCount, 1)
        })
      })
    })

    QUnit.module('if the first response does not link to the last page', contextHooks => {
      /*
       * This supposes that somehow the pagination links are either not present
       * or have excluded the last page, which is required for pagination
       * cheating to work for Gradebook. /
       */

      let customColumnsLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          customColumnsLoaded = loadCustomColumns()
          await network.allRequestsReady()
          const [{response}] = getRequests()
          response.setJson(exampleData.customColumns.slice(0, 1))
          response.send()
          await network.allRequestsReady()
          resolve()
        })
      })

      test('does not send additional requests', () => {
        strictEqual(getRequests().length, 1)
      })

      test('resolves the returned promise', async () => {
        equal(await customColumnsLoaded, null)
      })
    })
  })
})
/* eslint-enable no-async-promise-executor */
