/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {fireEvent, render, waitFor, screen} from '@testing-library/react'
import ExternalToolImporter from '../external_tool_importer'
import userEvent from '@testing-library/user-event'
import {EXTERNAL_CONTENT_READY} from '@canvas/external-tools/messages'
import processMigrationContentItem from '../../../../processMigrationContentItem'
import fakeENV from '@canvas/test-utils/fakeENV'

const modalTitle = 'External Tool'
const exampleUrl = 'http://example.com'

const env = {
  DEEP_LINKING_POST_MESSAGE_ORIGIN: 'http://canvas.test',
  context_asset_string: 'course_1',
}

describe('ExternalToolImporter', () => {
  const onSubmit = jest.fn()
  beforeEach(() => {
    fakeENV.setup(env)
    window.addEventListener('message', processMigrationContentItem)
  })

  const renderComponent = (overrideProps?: any) =>
    render(
      <ExternalToolImporter
        onSubmit={onSubmit}
        onCancel={jest.fn()}
        {...overrideProps}
        title={modalTitle}
        value="external_tool_1"
      />,
    )

  function sendPostMessage(data: unknown) {
    fireEvent(
      window,
      new MessageEvent('message', {
        data,
        origin: env.DEEP_LINKING_POST_MESSAGE_ORIGIN,
      }),
    )
  }

  const externalContentReady = (props = {}) => ({
    subject: EXTERNAL_CONTENT_READY,
    contentItems: [{url: exampleUrl, text: 'example'}],
    service: 'example',
    service_id: '1',
    ...props,
  })

  afterEach(() => {
    jest.clearAllMocks()
    fakeENV.teardown()
    window.removeEventListener('message', processMigrationContentItem)
  })

  it('renders the modal open button', async () => {
    const {getByText} = renderComponent()

    expect(getByText('Find a Course')).toBeInTheDocument()
  })

  it('modal is not opened by default', async () => {
    const {queryByText} = renderComponent()

    expect(queryByText(modalTitle)).not.toBeInTheDocument()
  })

  it('open the modal when the button is clicked', async () => {
    const {getByText, getByRole} = renderComponent()

    await userEvent.click(getByRole('button', {name: 'Find a Course'}))

    expect(getByText(modalTitle)).toBeInTheDocument()
  })

  it('close the modal when the cancel button is clicked', async () => {
    const {getByRole, queryByText, getByText} = renderComponent()
    await userEvent.click(getByRole('button', {name: 'Find a Course'}))
    expect(getByText(modalTitle)).toBeInTheDocument()

    await userEvent.click(getByRole('button', {name: 'Close'}))

    waitFor(() => expect(queryByText(modalTitle)).not.toBeInTheDocument())
  })

  it('close the modal when the modal was submitted', async () => {
    const {getByRole, getByText, queryByText} = renderComponent()
    await userEvent.click(getByRole('button', {name: 'Find a Course'}))
    expect(getByText(modalTitle)).toBeInTheDocument()

    sendPostMessage(externalContentReady())

    await waitFor(() => expect(queryByText(modalTitle)).not.toBeInTheDocument())
  })

  it('submits the form', async () => {
    const {getByRole} = renderComponent()
    await userEvent.click(getByRole('button', {name: 'Find a Course'}))
    sendPostMessage(externalContentReady())

    await waitFor(() => {
      expect(getByRole('button', {name: 'Add to Import Queue', hidden: true})).toBeInTheDocument()
    })

    await userEvent.click(getByRole('button', {name: 'Add to Import Queue', hidden: true}))

    expect(onSubmit).toHaveBeenCalledWith({
      settings: {file_url: exampleUrl},
      errored: false,
      selective_import: false,
    })
  })

  it('focuses on input after course input error', async () => {
    const {getByRole, getByTestId} = renderComponent()
    await userEvent.click(getByRole('button', {name: 'Add to Import Queue', hidden: true}))
    await expect(getByTestId('find-course-button')).toHaveFocus()
  })

  describe('external content url is empty', () => {
    it('does not submit the form', async () => {
      const {getByRole} = renderComponent()
      await userEvent.click(getByRole('button', {name: 'Find a Course'}))
      sendPostMessage(externalContentReady({contentItems: [{url: null, text: 'example'}]}))

      await userEvent.click(getByRole('button', {name: 'Add to Import Queue', hidden: true}))

      expect(onSubmit).not.toHaveBeenCalled()
    })
  })
})
