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
import 'jquery-migrate' // required
import {Provider} from 'react-redux'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

import {ConnectedCourseSidebar} from '../CourseSidebar'
import getSampleData from './getSampleData'

import {createStore, applyMiddleware} from 'redux'
import {thunk} from 'redux-thunk'
import rootReducer from '@canvas/blueprint-courses/react/reducer'
import type {Course, MigrationState, UnsyncedChange} from '../../types'
import type CourseSidebar from '../CourseSidebar'

let sidebarContentRef: HTMLSpanElement | null = null

interface CourseSidebarTestState extends Record<string, unknown> {
  masterCourse: {id: string; enrollment_term_id: string; name: string}
  existingAssociations: Course[]
  associations: Course[]
  unsyncedChanges: UnsyncedChange[]
  migrationStatus: MigrationState
  canManageCourse: boolean
  hasLoadedAssociations: boolean
  hasLoadedUnsyncedChanges: boolean
  hasCheckedMigration: boolean
  canAutoPublishCourses: boolean
  hasAssociationChanges: boolean
  willAddAssociations: boolean
  willPublishCourses: boolean
  isSavingAssociations: boolean
  isLoadingUnsyncedChanges: boolean
  isLoadingBeginMigration: boolean
}

const initialState: CourseSidebarTestState = {
  masterCourse: getSampleData().masterCourse,
  existingAssociations: getSampleData().courses as Course[],
  associations: getSampleData().courses as Course[],
  unsyncedChanges: getSampleData().unsyncedChanges as UnsyncedChange[],
  migrationStatus: 'unknown',
  canManageCourse: true,
  hasLoadedAssociations: true,
  hasLoadedUnsyncedChanges: true,
  hasCheckedMigration: false,
  canAutoPublishCourses: false,
  hasAssociationChanges: false,
  willAddAssociations: false,
  willPublishCourses: false,
  isSavingAssociations: false,
  isLoadingUnsyncedChanges: false,
  isLoadingBeginMigration: false,
}

const defaultProps = () => ({
  contentRef: (cr: HTMLSpanElement | null) => {
    sidebarContentRef = cr
  },
  routeTo: () => {},
  realRef: (_c: CourseSidebar | null) => {},
})

function mockStore(storeInitialState: CourseSidebarTestState) {
  return applyMiddleware(thunk)(createStore)(rootReducer, storeInitialState)
}

function connect(props = defaultProps(), storeState: CourseSidebarTestState = initialState) {
  return (
    <Provider store={mockStore(storeState)}>
      <ConnectedCourseSidebar
        {...(props as unknown as React.ComponentProps<typeof ConnectedCourseSidebar>)}
      />
    </Provider>
  )
}

function getSidebarContent(): HTMLSpanElement {
  if (!sidebarContentRef) {
    throw new Error('sidebar content ref was not set')
  }
  return sidebarContentRef
}

const server = setupServer(
  http.get('/api/v1/courses/:courseId/blueprint_templates/default/migrations', () =>
    HttpResponse.json([{id: '1'}]),
  ),
  http.get('/api/v1/courses/:courseId/blueprint_templates/default/unsynced_changes', () =>
    HttpResponse.json([]),
  ),
)

describe('Course Sidebar component', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  test('renders the closed CourseSidebar component', () => {
    const tree = render(connect())
    const node = tree.container.querySelector('button')
    expect(node?.textContent?.trim()).toEqual('Open Blueprint Sidebar')
    tree.unmount()
  })

  test('renders the open CourseSidebar component', async () => {
    const tree = render(connect())
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    await waitFor(() => {
      expect(sidebarContentRef).toBeTruthy()
    })

    const sidebar = getSidebarContent()
    const rows = sidebar.querySelectorAll('.bcs__row')

    expect(rows[0]?.querySelector('button#mcSidebarAsscBtn')).toBeTruthy()
    expect(rows[0]?.textContent?.trim()).toEqual(
      `Associations${initialState.existingAssociations.length}`,
    )

    expect(rows[1]?.querySelector('button#mcSyncHistoryBtn')).toBeTruthy()

    expect(rows[2]?.querySelector('button#mcUnsyncedChangesBtn')).toBeTruthy()
    expect(rows[2]?.querySelector('span')?.textContent).toEqual('Unsynced Changes')

    const count = Number(rows[2]?.querySelector('.bcs__row-right-content')?.textContent)
    expect(count).toEqual(initialState.unsyncedChanges.length)
    tree.unmount()
  })

  test('renders no Uncynced Changes link if there are none', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.unsyncedChanges = []
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = getSidebarContent()
    expect(sidebar.querySelector('button#mcUnsyncedChangesBtn')).toBeFalsy()
    tree.unmount()
  })

  test('renders no Uncynced Changes link if there are no associations', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.existingAssociations = []
    state.associations = []
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = getSidebarContent()
    expect(sidebar.querySelector('button#mcUnsyncedChangesBtn')).toBeFalsy()
    tree.unmount()
  })

  test('renders no Uncynced Changes link if sync is in progress', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.migrationStatus = 'imports_queued'
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = getSidebarContent()
    expect(sidebar.querySelector('button#mcUnsyncedChangesBtn')).toBeFalsy()
    tree.unmount()
  })

  test('renders no Associations link if the user not an admin', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.canManageCourse = false
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = getSidebarContent()
    expect(sidebar.querySelector('button#mcSidebarAsscBtn')).toBeFalsy()
    tree.unmount()
  })

  test('renders Sync button if has associations and sync is active and no unsyced changes', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.unsyncedChanges = []
    state.migrationStatus = 'imports_queued'
    state.hasCheckedMigration = true
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    await waitFor(() => {
      expect(sidebarContentRef).toBeTruthy()
    })
    const sidebar = getSidebarContent()
    expect(sidebar.querySelector('.bcs__migration-sync')).toBeTruthy()
    tree.unmount()
  })

  test('renders Sync button if has associations and has unsynced changes', async () => {
    const props = defaultProps()
    const state = {...initialState}
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    await waitFor(() => {
      expect(sidebarContentRef).toBeTruthy()
    })
    const sidebar = getSidebarContent()
    expect(sidebar.querySelector('.bcs__migration-sync')).toBeTruthy()
    tree.unmount()
  })

  test('renders no Sync button if there are no associations', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.existingAssociations = []
    state.associations = []
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = getSidebarContent()
    expect(sidebar.querySelector('.bcs__migration-sync')).toBeFalsy()
    tree.unmount()
  })

  test('renders no Sync button if there are associations, but no unsynced changes and no sync in progress', async () => {
    const props = defaultProps()
    const state = {...initialState}
    state.unsyncedChanges = []
    const tree = render(connect(props, state))
    const button = tree.container.querySelector('button')
    const user = userEvent.setup()
    await user.click(button!)

    expect(sidebarContentRef).toBeTruthy()
    const sidebar = getSidebarContent()
    expect(sidebar.querySelector('.bcs__migration-sync')).toBeFalsy()
    tree.unmount()
  })
})
