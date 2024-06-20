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
import $ from 'jquery'
import 'jquery-migrate' // required
import {Provider} from 'react-redux'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import moxios from 'moxios'
import sinon from 'sinon'

import {ConnectedCourseSidebar} from '../CourseSidebar'
import MigrationStates from '@canvas/blueprint-courses/react/migrationStates'
import getSampleData from './getSampleData'

import {createStore, applyMiddleware} from 'redux'
import {thunk} from 'redux-thunk'
import rootReducer from '@canvas/blueprint-courses/react/reducer'

let clock
let sidebarContentRef = null

const initialState = {
  masterCourse: getSampleData().masterCourse,
  existingAssociations: getSampleData().courses,
  unsyncedChanges: getSampleData().unsyncedChanges,
  migrationStatus: MigrationStates.states.unknown,
  canManageCourse: true,
  hasLoadedAssociations: true,
  hasLoadedUnsyncedChanges: true,
  canAutoPublishCourses: false,
}

const defaultProps = () => ({
  contentRef: cr => {
    sidebarContentRef = cr
  },
  routeTo: () => {},
})

function mockStore(initialState) {
  return applyMiddleware(thunk)(createStore)(rootReducer, initialState)
}

function connect(props = defaultProps(), storeState = initialState) {
  return (
    <Provider store={mockStore(storeState)}>
      <ConnectedCourseSidebar {...props} />
    </Provider>
  )
}

describe('Course Sidebar component', () => {
  beforeEach(() => {
    clock = sinon.useFakeTimers()
    moxios.install()
    moxios.stubRequest('/api/v1/courses/4/blueprint_templates/default/migrations', {
      status: 200,
      response: [{id: '1'}],
    })
  })

  afterEach(() => {
    moxios.uninstall()
    clock.restore()
  })

  test('renders the closed CourseSidebar component', () => {
    const tree = render(connect())
    const node = tree.container.querySelector('button')
    expect(node.textContent.trim()).toEqual('Open Blueprint Sidebar')
    tree.unmount()
  })

  test('renders the open CourseSidebar component', async () => {
    const tree = render(connect())
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    clock.tick(500)
    expect(sidebarContentRef).toBeTruthy()

    const sidebar = $(sidebarContentRef)
    const rows = sidebar.find('.bcs__row')

    // associations
    expect(rows.eq(0).find('button#mcSidebarAsscBtn').size()).toBeTruthy()
    expect(rows.eq(0).text().trim()).toEqual(
      `Associations${initialState.existingAssociations.length}`
    )

    // sync history
    expect(rows.eq(1).find('button#mcSyncHistoryBtn').size()).toBeTruthy()

    // unsynced changes
    expect(rows.eq(2).find('button#mcUnsyncedChangesBtn').size()).toBeTruthy()
    expect(rows.eq(2).find('span').eq(0).text()).toEqual('Unsynced Changes')

    const count = Number(rows.eq(2).find('.bcs__row-right-content').text())
    expect(count).toEqual(initialState.unsyncedChanges.length)
    tree.unmount()
  })

  test('renders no Uncynced Changes link if there are none', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.unsyncedChanges = []
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = $(sidebarContentRef)

    // no unsynced changes
    expect(sidebar.find('button#mcUnsyncedChangesBtn').size()).toBeFalsy()
    tree.unmount()
  })

  test('renders no Uncynced Changes link if there are no associations', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.existingAssociations = []
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = $(sidebarContentRef)

    // no unsynced changes
    expect(sidebar.find('button#mcUnsyncedChangesBtn').size()).toBeFalsy()
    tree.unmount()
  })

  test('renders no Uncynced Changes link if sync is in progress', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.migrationStatus = MigrationStates.states.imports_queued
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = $(sidebarContentRef)

    // no unsynced changes
    expect(sidebar.find('button#mcUnsyncedChangesBtn').size()).toBeFalsy()
    tree.unmount()
  })

  test('renders no Associations link if the user not an admin', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.canManageCourse = false
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = $(sidebarContentRef)

    // no unsynced changes
    expect(sidebar.find('button#mcSidebarAsscBtn').size()).toBeFalsy()
    tree.unmount()
  })

  test('renders Sync button if has associations and sync is active and no unsyced changes', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.unsyncedChanges = []
    state.migrationStatus = MigrationStates.states.imports_queued
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    clock.tick(500)
    expect(sidebarContentRef).toBeTruthy()
    const sidebar = $(sidebarContentRef)

    expect(sidebar.find('.bcs__migration-sync').size()).toBeTruthy()
    tree.unmount()
  })

  test('renders Sync button if has associations and has unsynced changes', async () => {
    const props = defaultProps()
    const state = {...initialState}
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    clock.tick(500)
    expect(sidebarContentRef).toBeTruthy()
    const sidebar = $(sidebarContentRef)

    expect(sidebar.find('.bcs__migration-sync').size()).toBeTruthy()
    tree.unmount()
  })

  test('renders no Sync button if there are no associations', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.existingAssociations = []
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = $(sidebarContentRef)

    expect(sidebar.find('.bcs__migration-sync').size()).toBeFalsy()
    tree.unmount()
  })

  test('renders no Sync button if there are associations, but no unsynced changes and no sync in progress', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.unsyncedChanges = []
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = $(sidebarContentRef)

    expect(sidebar.find('.bcs__migration-sync').size()).toBeFalsy()
    tree.unmount()
  })
})
