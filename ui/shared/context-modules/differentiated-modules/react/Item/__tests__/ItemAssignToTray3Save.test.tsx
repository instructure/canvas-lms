/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {reloadWindow} from '@canvas/util/globalUtils'
import {act, cleanup, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {ADHOC_WITHOUT_STUDENTS} from '../../__tests__/mocks'
import {
  DEFAULT_PROPS,
  OVERRIDES_URL,
  renderComponent,
  SECTIONS_DATA,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
  http,
  HttpResponse,
} from './ItemAssignToTrayTestUtils'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null}

describe('ItemAssignToTray - Save Operations', () => {
  const originalLocation = window.location
  const DATE_DETAILS = `/api/v1/courses/${DEFAULT_PROPS.courseId}/assignments/${DEFAULT_PROPS.itemContentId}/date_details`
  const DATE_DETAILS_OBJ = {
    id: '23',
    due_at: '2023-10-05T12:00:00Z',
    unlock_at: '2023-10-01T12:00:00Z',
    lock_at: '2023-11-01T12:00:00Z',
    only_visible_to_overrides: false,
    visible_to_everyone: true,
    overrides: [],
  }

  let lastPutBody: string | null = null
  let lastGetMethod: string | null = null

  beforeAll(() => {
    setupFlashHolder()
    server.listen()
  })

  beforeEach(() => {
    lastPutBody = null
    lastGetMethod = null
    setupEnv()
    setupBaseMocks()
    server.use(
      http.get(OVERRIDES_URL, () => {
        return HttpResponse.json(DATE_DETAILS_OBJ)
      }),
      http.put(DATE_DETAILS, async ({request}) => {
        lastPutBody = await request.text()
        return HttpResponse.json({})
      }),
      http.get('/api/v1/courses/1/assignments/24/date_details', ({request}) => {
        lastGetMethod = request.method
        return HttpResponse.json({
          id: '24',
          due_at: '2023-09-30T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          only_visible_to_overrides: false,
          visible_to_everyone: true,
          overrides: [],
        })
      }),
    )
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    server.resetHandlers()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('creates new assignment overrides', async () => {
    const {findByTestId, findByText, getByRole, findAllByText} = renderComponent()
    const assigneeSelector = await findByTestId('assignee_selector')
    act(() => assigneeSelector.click())
    const option1 = await findByText(SECTIONS_DATA[0].name)
    act(() => option1.click())

    getByRole('button', {name: 'Save'}).click()
    expect((await findAllByText(`${DEFAULT_PROPS.itemName} updated`))[0]).toBeInTheDocument()
    await waitFor(() => {
      expect(lastPutBody).not.toBeNull()
    })
    const {id, overrides, only_visible_to_overrides, visible_to_everyone, ...payloadValues} =
      DATE_DETAILS_OBJ
    const expectedPayload = JSON.stringify({
      ...payloadValues,
      reply_to_topic_due_at: null,
      required_replies_due_at: null,
      peer_review_available_from: null,
      peer_review_due_at: null,
      peer_review_available_to: null,
      only_visible_to_overrides,
      assignment_overrides: [
        {
          course_section_id: SECTIONS_DATA[0].id,
          title: SECTIONS_DATA[0].name,
          ...payloadValues,
          unassign_item: false,
        },
      ],
    })
    expect(lastPutBody).toEqual(expectedPayload)
  })

  it('calls onDismiss after saving', async () => {
    const onDismissMock = vi.fn()
    const {findAllByTestId, findByText, getByTestId, findAllByText} = renderComponent({
      onDismiss: onDismissMock,
    })
    const assigneeSelector = (await findAllByTestId('assignee_selector'))[0]
    assigneeSelector.click()
    const option1 = await findByText(SECTIONS_DATA[0].name)
    option1.click()
    const saveButton = getByTestId('differentiated_modules_save_button')
    saveButton.click()
    expect((await findAllByText(`${DEFAULT_PROPS.itemName} updated`))[0]).toBeInTheDocument()
    await waitFor(() => {
      expect(onDismissMock).toHaveBeenCalled()
    })
  })

  it('Save does not persist changes when a card is invalid', async () => {
    const onDismissMock = vi.fn()
    const {getAllByTestId, getByRole, getByText} = renderComponent({
      itemContentId: '24',
      onDismiss: onDismissMock,
    })
    await waitFor(() => {
      expect(getAllByTestId('item-assign-to-card')).toHaveLength(1)
    })
    const savebtn = getByRole('button', {name: 'Save'})

    savebtn.click()
    expect(getByText('Please fix errors before continuing')).toBeInTheDocument()
    expect(lastGetMethod).toBe('GET')
    expect(onDismissMock).not.toHaveBeenCalled()
  })

  // TODO: flaky in Vitest - reloadWindow mock not called within waitFor timeout
  it.skip('reloads the page after saving', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByTestId, findAllByTestId, findByText} = renderComponent()
    const assigneeSelector = (await findAllByTestId('assignee_selector'))[0]
    assigneeSelector.click()
    const option1 = await findByText(SECTIONS_DATA[0].name)
    await user.click(option1)
    const save = getByTestId('differentiated_modules_save_button')
    await waitFor(() => expect(save).not.toBeDisabled())
    await user.click(save)
    await waitFor(() => {
      expect(reloadWindow).toHaveBeenCalled()
    })
  })

  it('does not reload the page after saving if onSave is passed', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const onSave = vi.fn()
    const {getByTestId, findAllByTestId, findByText, unmount} = renderComponent({onSave})
    const assigneeSelector = (await findAllByTestId('assignee_selector'))[0]
    assigneeSelector.click()
    const option1 = await findByText(SECTIONS_DATA[3].name)
    option1.click()

    const save = getByTestId('differentiated_modules_save_button')
    await waitFor(() => expect(save).not.toBeDisabled())
    await user.click(save)
    await waitFor(() => {
      expect(onSave).toHaveBeenCalled()
    })
    expect(reloadWindow).not.toHaveBeenCalled()
    unmount()
  })

  it('does not show cards for ADHOC override with no students', async () => {
    server.use(
      http.get(OVERRIDES_URL, () => {
        return HttpResponse.json(ADHOC_WITHOUT_STUDENTS)
      }),
    )
    const {findAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(1)
  })

  it('does not include ADHOC overrides without students when saving', async () => {
    server.use(
      http.get(OVERRIDES_URL, () => {
        return HttpResponse.json(ADHOC_WITHOUT_STUDENTS)
      }),
    )
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {findByTestId, findAllByText, findAllByTestId, findByText} = renderComponent()
    const assigneeSelector = (await findAllByTestId('assignee_selector'))[0]
    assigneeSelector.click()
    const option1 = await findByText(SECTIONS_DATA[0].name)
    option1.click()
    const cards = await findAllByTestId('item-assign-to-card')
    // renders only 1 valid card
    expect(cards).toHaveLength(1)
    const save = await findByTestId('differentiated_modules_save_button')
    await user.click(save)
    expect((await findAllByText(`${DEFAULT_PROPS.itemName} updated`))[0]).toBeInTheDocument()
    await waitFor(() => {
      expect(lastPutBody).not.toBeNull()
    })
    const requestBody = JSON.parse(lastPutBody!)
    // filters out invalid overrides
    expect(requestBody.assignment_overrides).toHaveLength(2)
  })

  it('disables Save button if no changes have been made', async () => {
    // There are some callbacks that update the cards, they are passed by the tray wrappers
    // We may consider a way to mock those callbacks
    // or moving the tests to the tray wrappers or selenium specs
    const onSave = vi.fn()
    const {getByTestId, findAllByTestId, findByText} = renderComponent({onSave})
    const saveButton = getByTestId('differentiated_modules_save_button')
    const assigneeSelector = (await findAllByTestId('assignee_selector'))[0]
    assigneeSelector.click()
    const option1 = await findByText(SECTIONS_DATA[0].name)
    option1.click()
    saveButton.click()
    await waitFor(() => {
      expect(onSave).toHaveBeenCalled()
    })
  })

  describe('required due dates', () => {
    beforeEach(() => {
      // @ts-expect-error - global.ENV is a Canvas global not in TS types
      global.ENV = {
        // @ts-expect-error - global.ENV is a Canvas global not in TS types
        ...global.ENV,
        DUE_DATE_REQUIRED_FOR_ACCOUNT: true,
      }
    })

    it('validates if required due dates are set before applying changes', async () => {
      const {getByTestId, getAllByTestId, findAllByTestId, getByText, getAllByText, findByText} =
        renderComponent({
          postToSIS: true,
        })
      // wait until the cards are loaded
      const cards = await findAllByTestId('item-assign-to-card')
      expect(cards[0]).toBeInTheDocument()

      const addCardBtn = getAllByTestId('add-card')[0]
      act(() => addCardBtn.click())
      const assigneeSelector = (await findAllByTestId('assignee_selector'))[0]
      assigneeSelector.click()
      const option1 = await findByText(SECTIONS_DATA[0].name)
      option1.click()

      getByTestId('differentiated_modules_save_button').click()

      expect(getAllByText('Please add a due date')[0]).toBeInTheDocument()
      expect(getByText('Please fix errors before continuing')).toBeInTheDocument()
      // tray stays open
      expect(getByText('Assignment | 10 pts')).toBeInTheDocument()
    })
  })
})
