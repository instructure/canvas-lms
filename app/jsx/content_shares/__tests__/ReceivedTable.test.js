/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'
import ReceivedTable from 'jsx/content_shares/ReceivedTable'
import {
  assignmentShare,
  readDiscussionShare,
  unreadDiscussionShare
} from 'jsx/content_shares/__tests__/test-utils'

describe('content shares table', () => {
  it('renders only table header and no body rows when there are no shares', () => {
    const {container} = render(<ReceivedTable shares={[]} />)
    expect(container.querySelector('th')).toBeInTheDocument()
    expect(container.querySelector('td')).not.toBeInTheDocument()
  })

  it('renders share data', () => {
    const {container, getByText, getAllByText} = render(
      <ReceivedTable shares={[assignmentShare]} />
    )
    expect(container.querySelector('th')).toBeInTheDocument()
    expect(container.querySelector('td')).toBeInTheDocument()
    expect(getByText(assignmentShare.name)).toBeInTheDocument()
    expect(getByText('Assignment')).toBeInTheDocument()
    expect(getByText(assignmentShare.sender.display_name)).toBeInTheDocument()
    expect(getAllByText(/2019/)[0]).toBeInTheDocument()
    expect(getByText(/manage options/i)).toBeInTheDocument()
  })

  it('renders multiple rows of share data', () => {
    const {getByText} = render(<ReceivedTable shares={[assignmentShare, readDiscussionShare]} />)
    expect(getByText(assignmentShare.name)).toBeInTheDocument()
    expect(getByText('Assignment')).toBeInTheDocument()

    expect(getByText(readDiscussionShare.name)).toBeInTheDocument()
    expect(getByText('Discussion Topic')).toBeInTheDocument()
  })

  it('renders no unread dot for read items', () => {
    const {queryByTestId} = render(<ReceivedTable shares={[readDiscussionShare]} />)
    expect(queryByTestId('received-table-row-unread')).toBeNull()
  })

  it('renders an unread dot for unread items', () => {
    const {queryByTestId} = render(<ReceivedTable shares={[unreadDiscussionShare]} />)
    expect(queryByTestId('received-table-row-unread')).toBeInTheDocument()
  })

  it('calls the onUpdate action if the unread dot is clicked on', () => {
    const onUpdate = jest.fn()

    const {getByTestId} = render(
      <ReceivedTable shares={[unreadDiscussionShare]} onUpdate={onUpdate} />
    )
    fireEvent.click(getByTestId('received-table-row-unread'))
    expect(onUpdate).toHaveBeenCalledWith(unreadDiscussionShare.id, {read_state: 'read'})
  })

  it('triggers handler for preview menu action', () => {
    const onPreview = jest.fn()
    const onImport = jest.fn()

    const {getByText, getByTestId} = render(
      <ReceivedTable shares={[assignmentShare]} onPreview={onPreview} onImport={onImport} />
    )
    fireEvent.click(getByText(/manage options/i))
    const previewOption = getByTestId('preview-menu-action')
    fireEvent.click(previewOption)
    expect(onPreview).toHaveBeenCalledTimes(1)
    expect(onPreview).toHaveBeenCalledWith(assignmentShare)
    expect(onImport).toHaveBeenCalledTimes(0)
  })

  it('triggers handler for import menu action', () => {
    const onPreview = jest.fn()
    const onImport = jest.fn()

    const {getByText, getByTestId} = render(
      <ReceivedTable shares={[assignmentShare]} onPreview={onPreview} onImport={onImport} />
    )
    fireEvent.click(getByText(/manage options/i))
    const previewOption = getByTestId('import-menu-action')
    fireEvent.click(previewOption)
    expect(onImport).toHaveBeenCalledTimes(1)
    expect(onImport).toHaveBeenCalledWith(assignmentShare)
    expect(onPreview).toHaveBeenCalledTimes(0)
  })

  it('triggers handler for remove menu action', () => {
    const onRemove = jest.fn()
    const {getByText} = render(<ReceivedTable shares={[assignmentShare]} onRemove={onRemove} />)
    fireEvent.click(getByText(/manage options/i))
    fireEvent.click(getByText('Remove'))
    expect(onRemove).toHaveBeenCalledWith(assignmentShare)
  })
})
