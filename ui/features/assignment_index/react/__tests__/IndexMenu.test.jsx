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
import { render, screen, fireEvent, cleanup} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import Actions from '../actions/IndexMenuActions'
import IndexMenu from '../IndexMenu'

jest.mock('../actions/IndexMenuActions', () => ({
  ...jest.requireActual('../actions/IndexMenuActions').default,
  apiGetLaunches: jest.fn(),
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

const renderComponent = (overrides={}, initialState={}) => {
  return render(<IndexMenu {...generateProps(overrides, initialState)} />)
}

describe('AssignmentsIndexMenu', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = { ...window.ENV }

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
    expect(triggers.length).toBe(1)

    const options = container.querySelectorAll('.al-options')
    expect(options.length).toBe(1)
  })

  it('renders a bulk edit option if property is specified', () => {
    const requestBulkEditFn = jest.fn()
    const {getAllByText} = renderComponent({ requestBulkEdit: requestBulkEditFn })
    const menuitem = getAllByText("Edit Assignment Dates")
    expect(menuitem.length).toBe(1)
    // click menuitem:
    fireEvent.click(menuitem[0])
    expect(requestBulkEditFn).toHaveBeenCalled()
  })

  it('does not render a bulk edit option if property is not specified', () => {
    const {queryByText} = renderComponent()
    // expect no element with text "Edit Assignment Dates":
    expect(queryByText("Edit Assignment Dates")).toBeNull()
  })

  it("doesn't show an LTI tool modal if modalIsOpen is not true", () => {
    renderComponent()
    expect(screen.queryByRole('dialog')).toBeNull()
  })

  it('shows the LTI tool modal state if modalIsOpen is true', () => {
    renderComponent({}, {
      modalIsOpen: true,
      selectedTool: {
        placements: {course_assignments_menu: {title: 'foo'}},
        definition_id: 100,
      },
    })
    expect(screen.queryByRole('dialog')).not.toBeNull()
  })

  it('renders no iframe when there is no selectedTool in state', () => {
    const {container} = renderComponent({}, {selectedTool: null})
    const iframes = container.querySelectorAll('iframe')
    expect(iframes.length).toBe(0)
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
    expect(iframes.length).toBe(1)
  })

  test('onWeightedToggle dispatches expected actions', () => {
    const props = generateProps()
    const store = props.store
    const component = new IndexMenu(props)
    const actionsCount = store.dispatchedActions.length

    component.onWeightedToggle(true)
    expect(store.dispatchedActions.length).toBe(actionsCount + 1)
    expect(store.dispatchedActions[actionsCount].type).toBe(Actions.SET_WEIGHTED)
    expect(store.dispatchedActions[actionsCount].payload).toBe(true)

    component.onWeightedToggle(false)
    expect(store.dispatchedActions.length).toBe(actionsCount + 2)
    expect(store.dispatchedActions[actionsCount + 1].type).toBe(Actions.SET_WEIGHTED)
    expect(store.dispatchedActions[actionsCount + 1].payload).toBe(false)
  })

  it('renders a dropdown menu with one option when sync to sis conditions are not met', () => {
    const {container} = renderComponent()
    const options = container.querySelectorAll('li')
    expect(options.length).toBe(1)
  })

  it('renders a dropdown menu with two options when sync to sis conditions are met', () => {
    ENV.POST_TO_SIS_DEFAULT = true
    ENV.HAS_ASSIGNMENTS = true
    const {container} = renderComponent()
    const options = container.querySelectorAll('li')
    expect(options.length).toBe(2)
  })

  it('renders a dropdown menu with one option when sync to sis conditions are not met', () => {
    ENV.POST_TO_SIS_DEFAULT = true
    ENV.HAS_ASSIGNMENTS = false
    const {container} = renderComponent()
    const options = container.querySelectorAll('li')
    expect(options.length).toBe(1)
  })

  describe('tool content return', () => {
    const origin = 'http://example.com'
    let mockWindowLocationReload

    beforeEach(() => {
      ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = origin

      ENV.assignment_index_menu_tools = [
        {id: '1', title: 'test', base_url: 'https://example.com/launch'},
      ]

      mockWindowLocationReload = jest.fn()
      const mockLocation = { ...window.location, reload: mockWindowLocationReload }
      jest.spyOn(window, 'location', 'get').mockImplementation(() => mockLocation)
    })

    function makeMountPointUsedForTray(container) {
      const mountPoint = document.createElement('div')
      mountPoint.id = 'external-tool-mount-point'
      container.appendChild(mountPoint)
      expect(container.querySelectorAll('#external-tool-mount-point').length).toBe(1)
    }

    function openTray(container) {
      const links = container.querySelectorAll('a')
      fireEvent.click(links[links.length - 1])
    }

    function sendExternalContentReadyMessage() {
      const item = {service_id: 1, hello: 'world'}
      const data = {
        subject: 'externalContentReady',
        contentItems: [item],
        service_id: item.service_id,
      }

      // trigger event
      fireEvent(window, new MessageEvent('message', {data, origin}))
    }

    // It would be nice to have a test for the LTI 1.3 postMessage handler too,
    // but the handler is set up index.js, not in IndexMenu, so we can't test
    // that here.

    it('reloads the page when assignment_index_menu receives and LTI 1.1 externalContentReady message', () => {
      const {container} = renderComponent({sisName: "test1"})

      makeMountPointUsedForTray(container)
      openTray(container)
      sendExternalContentReadyMessage()
      expect(mockWindowLocationReload).toHaveBeenCalledTimes(1)
    })

    // If we don't clean up, the tray component is orphaned and its listener
    // persists beyond individual tests
    it('clears the window listener handler when unmounted', () => {
      let container

      container = renderComponent({sisName: "test2"}).container
      makeMountPointUsedForTray(container)
      openTray(container)

      cleanup()
      expect(mockWindowLocationReload).toHaveBeenCalledTimes(0)

      container = renderComponent({sisName: "test2"}).container
      makeMountPointUsedForTray(container)
      openTray(container)

      sendExternalContentReadyMessage()
      expect(mockWindowLocationReload).toHaveBeenCalledTimes(1)
    })
  })
})
