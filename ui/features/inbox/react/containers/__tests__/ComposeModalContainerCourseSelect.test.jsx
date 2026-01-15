/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from '@apollo/client'
import ComposeModalManager from '../ComposeModalContainer/ComposeModalManager'
import {fireEvent, render} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {handlers, inboxSettingsHandlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {setupServer} from 'msw/node'
import React from 'react'
import {ConversationContext} from '../../../util/constants'
import * as uploadFileModule from '@canvas/upload-file'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/upload-file')

vi.mock('../../../util/utils', async () => ({
  ...(await vi.importActual('../../../util/utils')),
  responsiveQuerySizes: vi.fn().mockReturnValue({
    desktop: {minWidth: '768px'},
  }),
}))

describe('ComposeModalContainer - Course Select', () => {
  const server = setupServer(...handlers.concat(inboxSettingsHandlers()))

  beforeAll(() => {
    server.close()
    server.listen({onUnhandledRequest: 'error'})

    window.matchMedia = vi.fn().mockImplementation(() => ({
      matches: true,
      media: '',
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }))
  })

  beforeEach(() => {
    uploadFileModule.uploadFiles.mockResolvedValue([])
    fakeENV.setup({
      current_user_id: '1',
      CONVERSATIONS: {
        ATTACHMENTS_FOLDER_ID: 1,
        CAN_MESSAGE_ACCOUNT_CONTEXT: false,
      },
    })
  })

  afterEach(async () => {
    server.resetHandlers()
    vi.clearAllTimers()
    await waitForApolloLoading()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  const setup = ({setOnFailure = vi.fn(), setOnSuccess = vi.fn(), selectedIds = ['1']} = {}) =>
    render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
            <ComposeModalManager
              open={true}
              onDismiss={vi.fn()}
              onSelectedIdsChange={vi.fn()}
              selectedIds={selectedIds}
            />
          </ConversationContext.Provider>
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )

  it('queries graphql for courses', async () => {
    const component = setup()

    const select = await component.findByTestId('course-select-modal')
    fireEvent.click(select)

    const selectOptions = await component.findAllByText('Ipsum')
    expect(selectOptions.length).toBeGreaterThan(0)
  })

  it('removes enrollment duplicates that come from graphql', async () => {
    const component = setup()

    const select = await component.findByTestId('course-select-modal')
    fireEvent.click(select)

    const selectOptions = await component.findAllByText('Ipsum')
    expect(selectOptions).toHaveLength(3)
  })

  it('does not render All Courses option', async () => {
    const {findByTestId, queryByText} = setup()
    await waitForApolloLoading()
    const courseDropdown = await findByTestId('course-select-modal')
    fireEvent.click(courseDropdown)
    expect(await queryByText('All Courses')).not.toBeInTheDocument()
  })

  it('does not render concluded groups', async () => {
    const {findByTestId, queryByText} = setup()
    await waitForApolloLoading()
    const courseDropdown = await findByTestId('course-select-modal')
    fireEvent.click(courseDropdown)
    expect(await queryByText('concluded_group')).not.toBeInTheDocument()
  })

  it('does not render concluded courses', async () => {
    const {findByTestId, queryByText} = setup()
    await waitForApolloLoading()
    const courseDropdown = await findByTestId('course-select-modal')
    fireEvent.click(courseDropdown)
    expect(await queryByText('Fighting Magneto 202')).not.toBeInTheDocument()
  })
})
