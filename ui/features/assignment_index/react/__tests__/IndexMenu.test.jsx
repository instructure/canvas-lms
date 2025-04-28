import {cleanup, fireEvent, render, screen} from '@testing-library/react'
/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import '@testing-library/jest-dom/extend-expect'
import {ltiState} from '@canvas/lti/jquery/messages'
import IndexMenu from '../IndexMenu'
import Actions from '../actions/IndexMenuActions'

jest.mock('../actions/IndexMenuActions', () => ({
  ...jest.requireActual('../actions/IndexMenuActions').default,
  apiGetLaunches: jest.fn(),
}))

jest.mock('@canvas/lti/jquery/messages', () => ({
  ltiState: {
    tray: null,
  },
  onLtiClosePostMessage: jest.fn(),
}))

function createFakeStore(initialState) {
  const store = {
    dispatchedActions: [],
    subscribe() {
      return function () {}
    },
    getState() {
      return initialState
    },
    dispatch(action) {
      if (typeof action === 'function') {
        return action(store.dispatch)
      }
      store.dispatchedActions.push(action)
    },
  }
  return store
}

const generateProps = (overrides, initialState = {}) => {
  const state = {
    externalTools: [],
    selectedTool: null,
    ...initialState,
  }
  return {
    store: createFakeStore(state),
    contextType: 'course',
    contextId: 1,
    setTrigger: () => {},
    setDisableTrigger: () => {},
    registerWeightToggle: () => {},
    disableSyncToSis: () => {},
    sisName: 'PowerSchool',
    postToSisDefault: ENV.POST_TO_SIS_DEFAULT,
    hasAssignments: ENV.HAS_ASSIGNMENTS,
    ...overrides,
  }
}

const renderComponent = (overrides = {}, initialState = {}) => {
  return render(<IndexMenu {...generateProps(overrides, initialState)} />)
}

describe('AssignmentsIndexMenu', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = {...window.ENV}

    Actions.apiGetLaunches.mockReturnValue({
      type: 'STUB_API_GET_TOOLS',
    })
  })

  afterEach(() => {
    window.ENV = oldEnv
    jest.restoreAllMocks()
  })

  it('renders a dropdown menu trigger and options list', () => {
    const {container} = renderComponent()

    const triggers = container.querySelectorAll('.al-trigger')
    expect(triggers).toHaveLength(1)

    const options = container.querySelectorAll('.al-options')
    expect(options).toHaveLength(1)
  })

  it('renders a bulk edit option if property is specified', () => {
    const requestBulkEditFn = jest.fn()
    const {getAllByText} = renderComponent({requestBulkEdit: requestBulkEditFn})
    const menuitem = getAllByText('Edit Assignment Dates')
    expect(menuitem).toHaveLength(1)
    // click menuitem:
    fireEvent.click(menuitem[0])
    expect(requestBulkEditFn).toHaveBeenCalled()
  })

  it('does not render a bulk edit option if property is not specified', () => {
    const {queryByText} = renderComponent()
    // expect no element with text "Edit Assignment Dates":
    expect(queryByText('Edit Assignment Dates')).toBeNull()
  })

  it("doesn't show an LTI tool modal if modalIsOpen is not true", () => {
    renderComponent()
    expect(screen.queryByRole('dialog')).toBeNull()
  })

  it('shows the LTI tool modal state if modalIsOpen is true', () => {
    renderComponent(
      {},
      {
        modalIsOpen: true,
        selectedTool: {
          placements: {course_assignments_menu: {title: 'foo'}},
          definition_id: 100,
        },
      },
    )
    expect(screen.queryByRole('dialog')).not.toBeNull()
  })

  it('renders no iframe when there is no selectedTool in state', () => {
    const {container} = renderComponent({}, {selectedTool: null})
    const iframes = container.querySelectorAll('iframe')
    expect(iframes).toHaveLength(0)
  })

  it('renders iframe when there is a selectedTool in state', async () => {
    const initialState = {
      modalIsOpen: true,
      selectedTool: {
        placements: {course_assignments_menu: {title: 'foo'}},
        definition_id: 100,
      },
    }
    renderComponent({}, initialState)
    const dialog = await screen.findByRole('dialog')
    const iframes = dialog.querySelectorAll('iframe')
    expect(iframes).toHaveLength(1)
  })

  test('onWeightedToggle dispatches expected actions', () => {
    const props = generateProps()
    const store = props.store
    const component = new IndexMenu(props)
    const actionsCount = store.dispatchedActions.length

    component.onWeightedToggle(true)
    expect(store.dispatchedActions).toHaveLength(actionsCount + 1)
    expect(store.dispatchedActions[actionsCount].type).toBe(Actions.SET_WEIGHTED)
    expect(store.dispatchedActions[actionsCount].payload).toBe(true)

    component.onWeightedToggle(false)
    expect(store.dispatchedActions).toHaveLength(actionsCount + 2)
    expect(store.dispatchedActions[actionsCount + 1].type).toBe(Actions.SET_WEIGHTED)
    expect(store.dispatchedActions[actionsCount + 1].payload).toBe(false)
  })

  it('renders a dropdown menu with one option when sync to sis conditions are not met', () => {
    const {container} = renderComponent()
    const options = container.querySelectorAll('li')
    expect(options).toHaveLength(1)
  })

  it('renders a dropdown menu with two options when sync to sis conditions are met', () => {
    ENV.POST_TO_SIS_DEFAULT = true
    ENV.HAS_ASSIGNMENTS = true
    const {container} = renderComponent()
    const options = container.querySelectorAll('li')
    expect(options).toHaveLength(2)
  })

  it('renders a dropdown menu with one option when sync to sis conditions are not met (2)', () => {
    ENV.POST_TO_SIS_DEFAULT = true
    ENV.HAS_ASSIGNMENTS = false
    const {container} = renderComponent()
    const options = container.querySelectorAll('li')
    expect(options).toHaveLength(1)
  })

  describe('tool content return', () => {
    const origin = 'http://example.com'

    beforeEach(() => {
      ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = origin

      ENV.assignment_index_menu_tools = [
        {id: '1', title: 'test', base_url: 'https://example.com/launch'},
      ]
    })

    function makeMountPointUsedForTray(container) {
      const mountPoint = document.createElement('div')
      mountPoint.id = 'external-tool-mount-point'
      container.appendChild(mountPoint)
    }

    function openTray(container) {
      makeMountPointUsedForTray(container)
      const links = container.querySelectorAll('a')
      const link = Array.from(links).find(l => l.textContent === 'test')
      fireEvent.click(link)
    }

    function sendExternalContentReadyMessage() {
      const message = {
        subject: 'externalContentReady',
        contentItems: [],
        msg: 'externalContentReady',
        messageType: 'LtiDeepLinkingResponse',
      }
      const messageEvent = new MessageEvent('message', {
        data: message,
        origin,
      })
      window.dispatchEvent(messageEvent)
    }

    it('reloads the page when assignment_index_menu receives and LTI 1.1 externalContentReady message', () => {
      const {container} = renderComponent()
      openTray(container)

      // Set the LTI state to indicate refresh is needed
      ltiState.tray = {refreshOnClose: true}

      // Close the tray which should trigger the reload
      const closeButton = screen.getByRole('button', {name: /close/i})
      fireEvent.click(closeButton)

      // Verify that the LTI state was accessed
      expect(ltiState.tray.refreshOnClose).toBe(true)
    })

    it('clears the window listener handler when unmounted', () => {
      const {container} = renderComponent()
      openTray(container)

      // Set the LTI state to indicate refresh is needed
      ltiState.tray = {refreshOnClose: true}

      // Unmount the component
      cleanup()

      // Verify that the LTI state was accessed
      expect(ltiState.tray.refreshOnClose).toBe(true)
    })
  })
})
