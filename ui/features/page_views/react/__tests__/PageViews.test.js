/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import {shallow} from 'enzyme'
import {render, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {PageViews} from '../PageViews'
import {act} from 'react-dom/test-utils'

import moment from 'moment'
import {unfudgeDateForProfileTimezone} from '@canvas/datetime/date-functions'

const processStartDate = date => {
  const dateStr = unfudgeDateForProfileTimezone(date).toISOString()
  return encodeURIComponent(dateStr)
}
const processEndDate = date => {
  const dateStr = moment(unfudgeDateForProfileTimezone(date)).add(1, 'days').toISOString()
  return encodeURIComponent(dateStr)
}

const defaultProps = (props = {}) => ({
  userID: '718',
  ...props
})
const PATH_START = `/api/v1/users/718/page_views`
const DEFAULT_PATH = `${PATH_START}?start_time=&end_time=&per_page=50`

afterEach(() => {
  fetchMock.restore()
})

it('renders correctly', () => {
  const wrapper = shallow(<PageViews {...defaultProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('Call api with error', () => {
  const expectedDate = 'Jan 24, 2022'
  const datePath = `${PATH_START}?start_time=${processStartDate(
    expectedDate
  )}&end_time=${processEndDate(expectedDate)}&per_page=50`

  fetchMock.mock(DEFAULT_PATH, 500)
  fetchMock.mock(datePath, {})

  const {getByTestId} = render(<PageViews {...defaultProps()} />)
  const inputDate = getByTestId('inputQueryDate')
  fireEvent.change(inputDate, {target: {value: expectedDate}})
  fireEvent.blur(inputDate)
  expect(inputDate.value).toBe(expectedDate)
})

// it('Show table without data', () => {

//   fetchMock.mock(DEFAULT_PATH, 200)
//   const {queryAllByRole} = render(<PageViews {...defaultProps()} />)
//   expect(queryAllByRole('row')).toHaveLength(1)
// })

it('Show data and load more data with scroll', async () => {
  const defaultData = {
    action: 'new',
    app_name: null,
    asset_type: null,
    asset_user_access_id: null,
    context_type: 'Course',
    contributed: false,
    controller: 'discussion_topics',
    created_at: '2022-01-26T17:48:34Z',
    developer_key_id: null,
    http_method: 'get',
    id: '32ea0daf-70ac-434e-9111-cf7c71d23df0',
    interaction_seconds: 6,
    links: {user: 893, context: 11, asset: null, real_user: 1, account: 2},
    participated: true,
    remote_ip: '::1',
    render_time: 0.498169,
    session_id: 'd268f88b12896612544921c836302c8e',
    summarized: null,
    updated_at: '2022-01-26T17:48:34Z',
    url: null,
    user_agent:
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36',
    user_request: true
  }
  const page1 = Array(50)
    .fill()
    .map(index => {
      const copy = {...defaultData}
      copy.url = `url ${index}`
      return copy
    })
  const page2 = Array(22)
    .fill()
    .map(index => {
      const copy = {...defaultData}
      copy.url = `url ${index}`
      return copy
    })

  fetchMock.mock(DEFAULT_PATH, {
    body: page1,
    status: 200,
    headers: {
      Link: '<http://canvas.docker/api/v1/users/37/page_views?page=2>; rel="next"'
    }
  })
  fetchMock.mock(`${DEFAULT_PATH}&page=2`, {
    body: page2,
    status: 200,
    headers: {
      Link: '<http://canvas.docker/api/v1/users/37/page_views?page=3>; rel="current"'
    }
  })
  let wrapper
  await act(async () => {
    wrapper = render(<PageViews {...defaultProps()} />)
  })
  const {getByTestId, queryAllByRole} = wrapper
  const scrollContainer = getByTestId('scrollContainer')
  jest.spyOn(scrollContainer, 'scrollTop', 'get').mockImplementation(() => 450)
  fireEvent.scroll(scrollContainer)

  expect(queryAllByRole('row')).toHaveLength(73)
})

it('Select the input date and reset the input date', () => {
  const expectedDate = 'Jan 27, 2021'

  const datePath = `${PATH_START}?start_time=${processStartDate(
    expectedDate
  )}&end_time=${processEndDate(expectedDate)}&per_page=50`
  fetchMock.mock(datePath, {})
  fetchMock.mock(DEFAULT_PATH, {})

  const {getByTestId} = render(<PageViews {...defaultProps()} />)
  const inputDate = getByTestId('inputQueryDate')
  fireEvent.change(inputDate, {target: {value: expectedDate}})
  fireEvent.blur(inputDate)
  expect(inputDate.value).toBe(expectedDate)
  fireEvent.change(inputDate, {target: {value: ''}})
  fireEvent.blur(inputDate)
  expect(inputDate.value).toBe('')
})

it('Select date and download file', () => {
  const expectedDate = 'Jan 27, 2022'
  const {getByTestId} = render(<PageViews {...defaultProps()} />)
  const inputDate = getByTestId('inputQueryDate')
  fireEvent.change(inputDate, {target: {value: expectedDate}})
  fireEvent.blur(inputDate)
  expect(inputDate.value).toBe(expectedDate)
  const pageViewLink = getByTestId('page_views_csv_link')
  fireEvent.click(pageViewLink)
  expect(pageViewLink).toBeInTheDocument()
})

it('Date with not result', () => {
  const expectedDate = 'Jan 27, 2022'
  const {getByTestId, queryAllByRole} = render(<PageViews {...defaultProps()} />)
  const inputDate = getByTestId('inputQueryDate')
  fireEvent.change(inputDate, {target: {value: expectedDate}})
  fireEvent.blur(inputDate)
  expect(inputDate.value).toBe(expectedDate)
  expect(queryAllByRole('row')).toHaveLength(1)
})
