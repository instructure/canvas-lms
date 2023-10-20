/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import DelayedPublishDialog from '../DelayedPublishDialog'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

const flushPromises = () => new Promise(setTimeout)

const fakePage = {
  url: 'a-page',
  title: 'A Page',
  page_id: 1281,
  published: false,
  created_at: '2022-08-02T18:51:44Z',
  updated_at: '2022-08-09T22:13:35Z',
  publish_at: '2022-11-01T22:00:00Z',
  body: '<p>Hello</p>',
}

function renderDialog(props) {
  return render(
    <DelayedPublishDialog
      name={props.name || 'A Page'}
      courseId={props.courseId || 123}
      contentId={props.contentId || 'a-page'}
      publishAt={props.publishAt || '2022-02-22T22:22:22Z'}
      onPublish={props.onPublish || jest.fn()}
      onUpdatePublishAt={props.onUpdatePublishAt || jest.fn()}
      onClose={props.onClose || jest.fn()}
    />
  )
}

describe('DelayedPublishDialog', () => {
  beforeAll(() => {
    doFetchApi.mockResolvedValue(fakePage)
  })

  beforeEach(() => {
    doFetchApi.mockClear()
  })

  it('shows the publish-at date', async () => {
    const {getByLabelText} = renderDialog({publishAt: '2022-03-03T14:00:00'})
    const input = getByLabelText('Choose a date')
    expect(input.value).toEqual('Thu, Mar 3, 2022, 2:00 PM')
  })

  it('publishes a page outright', async () => {
    const onPublish = jest.fn()
    const {getByLabelText, getByRole} = renderDialog({onPublish})
    fireEvent.click(getByLabelText('Published'))
    fireEvent.click(getByRole('button', {name: 'OK'}))
    expect(onPublish).toHaveBeenCalled()
  })

  it('cancels scheduled publication', async () => {
    const onUpdatePublishAt = jest.fn()
    const {getByLabelText, getByRole} = renderDialog({onUpdatePublishAt})
    fireEvent.click(getByLabelText('Unpublished'))
    fireEvent.click(getByRole('button', {name: 'OK'}))
    await flushPromises()
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/courses/123/pages/a-page',
      method: 'PUT',
      params: {wiki_page: {publish_at: null}},
    })
    expect(onUpdatePublishAt).toHaveBeenCalledWith(null)
  })

  it('changes the scheduled publication date', async () => {
    const onUpdatePublishAt = jest.fn()
    const {getByLabelText, getByRole} = renderDialog({onUpdatePublishAt})
    fireEvent.click(getByLabelText('Scheduled for publication'))
    const input = getByLabelText('Choose a date')
    fireEvent.change(input, {target: {value: '2022-03-03T00:00:00.000Z'}})
    fireEvent.blur(input)
    fireEvent.click(getByRole('button', {name: 'OK'}))
    await flushPromises()
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/courses/123/pages/a-page',
      method: 'PUT',
      params: {wiki_page: {publish_at: '2022-03-03T00:00:00.000Z'}},
    })
    expect(onUpdatePublishAt).toHaveBeenCalledWith('2022-03-03T00:00:00.000Z')
  })

  it('closes', async () => {
    const onClose = jest.fn()
    const {getByRole} = renderDialog({onClose})
    fireEvent.click(getByRole('button', {name: 'Close'}))
    expect(onClose).toHaveBeenCalled()
  })
})
