/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import PaginatedList from '../PaginatedList'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)

const fixturesDiv = document.createElement('div')
fixturesDiv.id = 'fixtures'
document.body.appendChild(fixturesDiv)

const paginatedListFixture = `
  <h3>Paginated List Spec</h3>
  <div id="list-wrapper">
    <ul></ul>
  </div>
`

let response
let template
let fixture
let el

const server = setupServer()

describe('PaginatedList', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    jest.useFakeTimers()

    response = [{value: 'one'}, {value: 'two'}]

    // fake template (mimics a handlebars function)
    template = opts => opts.map(opt => `<li>${opt.value}</li>`).join('')
    fixture = $(paginatedListFixture).appendTo('#fixtures')
    el = {
      wrapper: $('#list-wrapper'),
      list: $('#list-wrapper').find('ul'),
    }
  })

  afterEach(() => {
    jest.useRealTimers()
    fixture.remove()
  })

  test('should fetch and display results', async function () {
    server.use(
      http.get('*/api/v1/test.json', () => {
        return HttpResponse.json(response)
      }),
    )

    new PaginatedList(el.wrapper, {
      template,
      url: '/api/v1/test.json',
    })

    await jest.runAllTimersAsync()
    equal(el.list.children().length, 2)
  })

  test('should display a view more link if next page is available', async function () {
    server.use(
      http.get('*/api/v1/test.json', () => {
        return new HttpResponse(JSON.stringify(response), {
          headers: {
            'Content-Type': 'application/json',
            Link: '<http://api?page=bookmarkstuff>; rel="next"',
          },
        })
      }),
    )

    const list = new PaginatedList(el.wrapper, {
      template,
      url: '/api/v1/test.json',
    })

    await jest.runAllTimersAsync()
    ok(el.wrapper.find('.view-more-link').length > 0)
    equal(list.options.requestParams.page, 'bookmarkstuff')
  })

  test('should not display a view more link if there is no next page', async function () {
    server.use(
      http.get('*/api/v1/test.json', () => {
        return HttpResponse.json(response)
      }),
    )

    new PaginatedList(el.wrapper, {
      template,
      url: '/api/v1/test.json',
    })

    await jest.runAllTimersAsync()
    ok(el.wrapper.find('.view-more-link').length === 0)
  })

  test('should accept a template function', async function () {
    server.use(
      http.get('*/api/v1/test.json', () => {
        return HttpResponse.json(response)
      }),
    )

    new PaginatedList(el.wrapper, {
      template,
      url: '/api/v1/test.json',
    })

    await jest.runAllTimersAsync()
    equal(el.list.find('li:first-child').text(), 'one')
    equal(el.list.find('li:last-child').text(), 'two')
  })

  test('should accept a presenter function', async function () {
    server.use(
      http.get('*/api/v1/test.json', () => {
        return HttpResponse.json(response)
      }),
    )

    new PaginatedList(el.wrapper, {
      presenter: list => list.map(() => ({value: 'changed'})),
      template,
      url: '/api/v1/test.json',
    })

    await jest.runAllTimersAsync()
    equal(el.list.find('li:first-child').text(), 'changed')
  })

  test('should allow user to defer getJSON', function () {
    const getJSONSpy = jest.spyOn($, 'getJSON')
    new PaginatedList(el.wrapper, {
      start: false,
      template,
      url: '/api/v1/not-called.json',
    })
    expect(getJSONSpy).not.toHaveBeenCalled()
    getJSONSpy.mockRestore()
  })
})
