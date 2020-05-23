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
import CustomColumnsDataLoader from 'jsx/gradebook/default_gradebook/DataLoader/CustomColumnsDataLoader'
import PerformanceControls from 'jsx/gradebook/default_gradebook/PerformanceControls'
import {NetworkFake, setPaginationLinkHeader} from 'jsx/shared/network/NetworkFake'
import {RequestDispatch} from 'jsx/shared/network'

/* eslint-disable no-async-promise-executor */
QUnit.module('Gradebook > DataLoader > CustomColumnsDataLoader', suiteHooks => {
  function urlForColumn(columnId) {
    return `/api/v1/courses/1201/custom_gradebook_columns/${columnId}/data`
  }

  let dispatch
  let exampleData
  let gradebook
  let network
  let performanceControls

  suiteHooks.beforeEach(() => {
    exampleData = {
      customColumns: [
        {id: '2401', teacher_notes: true, hidden: true, title: 'Notes'},
        {id: '2402', teacher_notes: false, hidden: false, title: 'Other Notes'}
      ],

      customColumnData: {
        2401: [
          {content: '', custom_gradebook_column_id: '2401', id: '2801', user_id: '1101'},
          {content: '', custom_gradebook_column_id: '2401', id: '2802', user_id: '1102'},
          {content: '', custom_gradebook_column_id: '2401', id: '2803', user_id: '1103'}
        ],

        2402: [
          {content: '', custom_gradebook_column_id: '2402', id: '2804', user_id: '1102'},
          {content: '', custom_gradebook_column_id: '2402', id: '2805', user_id: '1101'},
          {content: '', custom_gradebook_column_id: '2402', id: '2806', user_id: '1103'}
        ]
      }
    }
  })

  QUnit.module('#loadCustomColumnsData()', hooks => {
    hooks.beforeEach(() => {
      network = new NetworkFake()
      dispatch = new RequestDispatch()
      performanceControls = new PerformanceControls()

      gradebook = createGradebook({
        context_id: '1201'
      })
      gradebook.gotCustomColumns(exampleData.customColumns)

      sinon.stub(gradebook, 'gotCustomColumnDataChunk')
    })

    hooks.afterEach(() => {
      network.restore()
    })

    function loadCustomColumnsData() {
      const dataLoader = new CustomColumnsDataLoader({dispatch, gradebook, performanceControls})
      return dataLoader.loadCustomColumnsData()
    }

    function getRequests(columnId = '.*') {
      return network.getRequests().filter(request => request.path.match(urlForColumn(columnId)))
    }

    test('sends a request to the custom columns url for each custom column', async () => {
      loadCustomColumnsData()
      await network.allRequestsReady()
      const requests = getRequests()
      strictEqual(requests.length, 2)
    })

    QUnit.module('when sending the initial requests', () => {
      test('uses each column id in the url', async () => {
        loadCustomColumnsData()
        await network.allRequestsReady()
        const requests = getRequests()
        deepEqual(
          requests.map(request => request.path),
          [urlForColumn('2401'), urlForColumn('2402')]
        )
      })

      test('sets the `include_hidden` parameter to `true`', async () => {
        loadCustomColumnsData()
        await network.allRequestsReady()
        const [{params}] = getRequests()
        strictEqual(params.include_hidden, 'true')
      })

      test('sets the `per_page` parameter to the configured per page maximum', async () => {
        performanceControls = new PerformanceControls({customColumnDataPerPage: 45})
        loadCustomColumnsData()
        await network.allRequestsReady()
        const [{params}] = getRequests()
        strictEqual(params.per_page, '45')
      })
    })

    QUnit.module('when the first page resolves for a request', contextHooks => {
      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          loadCustomColumnsData()
          await network.allRequestsReady()
          const [{response}] = getRequests('2401')
          setPaginationLinkHeader(response, {last: 3})
          response.setJson(exampleData.customColumnData[2401].slice(0, 1))
          response.send()
          await network.allRequestsReady()
          resolve()
        })
      })

      test('updates the gradebook custom column data', () => {
        strictEqual(gradebook.gotCustomColumnDataChunk.callCount, 1)
      })

      test('includes the column id when updating the gradebook', () => {
        const [columnId] = gradebook.gotCustomColumnDataChunk.lastCall.args
        strictEqual(columnId, '2401')
      })

      test('includes the loaded custom column data when updating the gradebook', () => {
        const [, customColumnData] = gradebook.gotCustomColumnDataChunk.lastCall.args
        deepEqual(customColumnData, exampleData.customColumnData[2401].slice(0, 1))
      })

      test('sends a request for each additional page for the related column', () => {
        const pages = getRequests('2401')
          .slice(1)
          .map(request => request.params.page)
        deepEqual(pages, ['2', '3'])
      })

      test('uses the same path for each page', () => {
        const [{path}] = getRequests('2401')
        getRequests('2401')
          .slice(1)
          .forEach(request => {
            equal(request.path, path)
          })
      })

      test('uses the same parameters for each page', () => {
        const [{params}] = getRequests('2401')
        getRequests('2401')
          .slice(1)
          .forEach(request => {
            const {page, ...pageParams} = request.params
            deepEqual(pageParams, params)
          })
      })
    })

    QUnit.module('when the first pages resolve for all requests', contextHooks => {
      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          loadCustomColumnsData()
          await network.allRequestsReady()

          const [request1] = getRequests('2401')
          setPaginationLinkHeader(request1.response, {last: 3})
          request1.response.setJson(exampleData.customColumnData[2401].slice(0, 1))
          request1.response.send()

          const [request2] = getRequests('2402')
          setPaginationLinkHeader(request2.response, {last: 3})
          request2.response.setJson(exampleData.customColumnData[2402].slice(0, 1))
          request2.response.send()

          await network.allRequestsReady()
          resolve()
        })
      })

      test('updates the gradebook custom column data for each column', () => {
        strictEqual(gradebook.gotCustomColumnDataChunk.callCount, 2)
      })

      test('includes the column id when updating the gradebook', () => {
        const calls = gradebook.gotCustomColumnDataChunk.getCalls()
        const columnIds = calls.map(call => call.args[0])
        deepEqual(columnIds, ['2401', '2402'])
      })

      test('includes the loaded custom column data when updating the gradebook', () => {
        const calls = gradebook.gotCustomColumnDataChunk.getCalls()
        const columnData = calls.map(call => call.args[1])
        deepEqual(columnData, [
          exampleData.customColumnData[2401].slice(0, 1),
          exampleData.customColumnData[2402].slice(0, 1)
        ])
      })

      test('sends a request for each additional page for each column', () => {
        const pageRequests = [...getRequests('2401').slice(1), ...getRequests('2402').slice(1)]
        const pages = pageRequests.map(request => request.params.page)
        deepEqual(pages, ['2', '3', '2', '3'])
      })
    })

    QUnit.module('when each additional page resolves', contextHooks => {
      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          loadCustomColumnsData()
          await network.allRequestsReady()

          // Resolve the first pages
          const [request2401_1] = getRequests('2401')
          setPaginationLinkHeader(request2401_1.response, {last: 3})
          request2401_1.response.setJson(exampleData.customColumnData[2401].slice(0, 1))
          request2401_1.response.send()

          const [request2402_1] = getRequests('2402')
          setPaginationLinkHeader(request2402_1.response, {last: 3})
          request2402_1.response.setJson(exampleData.customColumnData[2402].slice(0, 1))
          request2402_1.response.send()

          // Wait for additional page requests to register
          await network.allRequestsReady()

          // Resolve the remaining pages
          const [, request2401_2, request2401_3] = getRequests('2401')
          setPaginationLinkHeader(request2401_2.response, {last: 3})
          request2401_2.response.setJson(exampleData.customColumnData[2401].slice(1, 2))
          request2401_2.response.send()

          setPaginationLinkHeader(request2401_3.response, {last: 3})
          request2401_3.response.setJson(exampleData.customColumnData[2401].slice(2, 3))
          request2401_3.response.send()

          const [, request2402_2, request2402_3] = getRequests('2402')
          setPaginationLinkHeader(request2402_2.response, {last: 3})
          request2402_2.response.setJson(exampleData.customColumnData[2402].slice(1, 2))
          request2402_2.response.send()

          setPaginationLinkHeader(request2402_3.response, {last: 3})
          request2402_3.response.setJson(exampleData.customColumnData[2402].slice(2, 3))
          request2402_3.response.send()

          resolve()
        })
      })

      test('updates the gradebook custom column data for each column page', () => {
        strictEqual(gradebook.gotCustomColumnDataChunk.callCount, 6)
      })

      test('includes the column id when updating the gradebook', () => {
        const calls = gradebook.gotCustomColumnDataChunk.getCalls()
        const columnIds = calls.map(call => call.args[0])
        deepEqual(columnIds, ['2401', '2402', '2401', '2401', '2402', '2402'])
      })

      test('includes the loaded custom column data when updating the gradebook', () => {
        const calls = gradebook.gotCustomColumnDataChunk.getCalls()
        const columnData = calls.map(call => call.args[1])
        deepEqual(columnData, [
          exampleData.customColumnData[2401].slice(0, 1),
          exampleData.customColumnData[2402].slice(0, 1),
          exampleData.customColumnData[2401].slice(1, 2),
          exampleData.customColumnData[2401].slice(2, 3),
          exampleData.customColumnData[2402].slice(1, 2),
          exampleData.customColumnData[2402].slice(2, 3)
        ])
      })
    })

    QUnit.module('when all pages have resolved', contextHooks => {
      let customColumnsDataLoaded

      contextHooks.beforeEach(() => {
        return new Promise(async resolve => {
          customColumnsDataLoaded = loadCustomColumnsData()
          await network.allRequestsReady()

          // Resolve the first pages
          const [request2401_1] = getRequests('2401')
          setPaginationLinkHeader(request2401_1.response, {last: 3})
          request2401_1.response.setJson(exampleData.customColumnData[2401].slice(0, 1))
          request2401_1.response.send()

          const [request2402_1] = getRequests('2402')
          setPaginationLinkHeader(request2402_1.response, {last: 3})
          request2402_1.response.setJson(exampleData.customColumnData[2402].slice(0, 1))
          request2402_1.response.send()

          // Wait for additional page requests to register
          await network.allRequestsReady()

          // Resolve the remaining pages
          const [, request2401_2, request2401_3] = getRequests('2401')
          setPaginationLinkHeader(request2401_2.response, {last: 3})
          request2401_2.response.setJson(exampleData.customColumnData[2401].slice(1, 2))
          request2401_2.response.send()

          setPaginationLinkHeader(request2401_3.response, {last: 3})
          request2401_3.response.setJson(exampleData.customColumnData[2401].slice(2, 3))
          request2401_3.response.send()

          const [, request2402_2, request2402_3] = getRequests('2402')
          setPaginationLinkHeader(request2402_2.response, {last: 3})
          request2402_2.response.setJson(exampleData.customColumnData[2402].slice(1, 2))
          request2402_2.response.send()

          setPaginationLinkHeader(request2402_3.response, {last: 3})
          request2402_3.response.setJson(exampleData.customColumnData[2402].slice(2, 3))
          request2402_3.response.send()

          resolve()
        })
      })

      test('resolves the returned promise', async () => {
        equal(await customColumnsDataLoaded, null)
      })

      test('resolves the returned promise after updating the gradebook', () => {
        return customColumnsDataLoaded.then(() => {
          strictEqual(gradebook.gotCustomColumnDataChunk.callCount, 6)
        })
      })
    })
  })
})
/* eslint-enable no-async-promise-executor */
