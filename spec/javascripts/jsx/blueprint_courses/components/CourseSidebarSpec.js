/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import { Provider } from 'react-redux'
import * as enzyme from 'enzyme'
import moxios from 'moxios'

import {ConnectedCourseSidebar} from 'jsx/blueprint_courses/components/CourseSidebar'
import MigrationStates from 'jsx/blueprint_courses/migrationStates'
import sampleData from '../sampleData'
import mockStore from '../mockStore'

let clock
let sidebarContentRef = null

const initialState = {
  masterCourse: sampleData.masterCourse,
  existingAssociations: sampleData.courses,
  unsyncedChanges: sampleData.unsyncedChanges,
  migrationStatus: MigrationStates.states.unknown,
  canManageCourse: true,
  hasLoadedAssociations: true,
  hasLoadedUnsyncedChanges: true,
}

const defaultProps = () => ({
  contentRef: (cr) => { sidebarContentRef = cr },
  routeTo: () => {},
})

function connect (props = defaultProps(), storeState = initialState) {
  return (
    <Provider store={mockStore(storeState)}>
      <ConnectedCourseSidebar {...props} />
    </Provider>
  )
}

QUnit.module('Course Sidebar component', {
  setup () {
    clock = sinon.useFakeTimers()
    const appElement = document.createElement('div')
    appElement.id = 'application'
    document.getElementById('fixtures').appendChild(appElement)
    sidebarContentRef = null
    moxios.install()
    moxios.stubRequest('/api/v1/courses/4/blueprint_templates/default/migrations', {
      status: 200,
      response: [{id: '1'}],
    })
  },
  teardown () {
    moxios.uninstall()
    document.getElementById('fixtures').innerHTML = ''
    clock.restore()
  }
})

test('renders the closed CourseSidebar component', () => {
  const tree = enzyme.mount(connect())
  const node = tree.find('button')
  equal(node.text().trim(), 'Open sidebar')
  tree.unmount()
})

test('renders the open CourseSidebar component', () => {
  const tree = enzyme.mount(connect())
  tree.find('button').simulate('click')
  clock.tick(500)
  ok(sidebarContentRef, 'sidebar contents')

  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)
  const rows = sidebar.find('.bcs__row')

  // associations
  ok(rows.at(0).find('button#mcSidebarAsscBtn').exists(), 'Associations button')
  equal(rows.at(0).text().trim(), `Associations${initialState.existingAssociations.length}`, 'Associations count')

  // sync history
  ok(rows.at(1).find('button#mcSyncHistoryBtn').exists(), 'sync history button')

  // unsynced changes
  ok(rows.at(2).find('button#mcUnsyncedChangesBtn').exists(), 'unsynced changes button')
  equal(rows.at(2).find('span').at(0).text(), 'Unsynced Changes')

  const count = rows.at(2).find('.bcs__row-right-content').text()
  equal(count, initialState.unsyncedChanges.length, 'unsynced changes count')
  tree.unmount()
})

test('renders no Uncynced Changes link if there are none', () => {
  const props = defaultProps()
  const state = {...initialState}
  state.unsyncedChanges = []
  const tree = enzyme.mount(connect(props, state))
  tree.find('button').simulate('click')
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  // no unsynced changes
  notOk(sidebar.find('button#mcUnsyncedChangesBtn').exists())
  tree.unmount()
})

test('renders no Uncynced Changes link if there are no associations', () => {
  const props = defaultProps()
  const state = {...initialState}
  state.existingAssociations = []
  const tree = enzyme.mount(connect(props, state))
  tree.find('button').simulate('click')
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  // no unsynced changes
  notOk(sidebar.find('button#mcUnsyncedChangesBtn').exists())
  tree.unmount()
})

test('renders no Uncynced Changes link if sync is in progress', () => {
  const props = defaultProps()
  const state = {...initialState}
  state.migrationStatus = MigrationStates.states.imports_queued
  const tree = enzyme.mount(connect(props, state))
  tree.find('button').simulate('click')
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  // no unsynced changes
  notOk(sidebar.find('button#mcUnsyncedChangesBtn').exists())
  tree.unmount()
})

test('renders no Associations link if the user not an admin', () => {
  const props = defaultProps()
  const state = {...initialState}
  state.canManageCourse = false
  const tree = enzyme.mount(connect(props, state))
  tree.find('button').simulate('click')
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  // no unsynced changes
  notOk(sidebar.find('button#mcSidebarAsscBtn').exists())
  tree.unmount()
})

test('renders Sync button if has associations and sync is active and no unsyced changes', () => {
  const props = defaultProps()
  const state = {...initialState}
  state.unsyncedChanges = []
  state.migrationStatus = MigrationStates.states.imports_queued
  const tree = enzyme.mount(connect(props, state))
  tree.find('button').simulate('click')
  clock.tick(500)
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  ok(sidebar.find('MigrationSync').exists())
  tree.unmount()
})

test('renders Sync button if has associations and has unsynced changes', () => {
  const props = defaultProps()
  const state = {...initialState}
  const tree = enzyme.mount(connect(props, state))
  tree.find('button').simulate('click')
  clock.tick(500)
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  ok(sidebar.find('MigrationSync').exists())
  tree.unmount()
})

test('renders no Sync button if there are no associations', () => {
  const props = defaultProps()
  const state = {...initialState}
  state.existingAssociations = []
  const tree = enzyme.mount(connect(props, state))
  tree.find('button').simulate('click')
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  notOk(sidebar.find('MigrationSync').exists())
  tree.unmount()
})

test('renders no Sync button if there are associations, but no unsynced changes and no sync in progress', () => {
  const props = defaultProps()
  const state = {...initialState}
  state.unsyncedChanges = []
  const tree = enzyme.mount(connect(props, state))
  tree.find('button').simulate('click')
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  notOk(sidebar.find('MigrationSync').exists())
  tree.unmount()
})
