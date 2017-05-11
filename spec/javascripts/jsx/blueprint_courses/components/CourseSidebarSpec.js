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
import createStore from 'jsx/blueprint_courses/store'
import moxios from 'moxios'
import {ConnectedCourseSidebar} from 'jsx/blueprint_courses/components/CourseSidebar'
import MigrationStates from 'jsx/blueprint_courses/migrationStates'
import sampleData from '../sampleData'

let sidebarContentRef = null
const noop = () => {}

const defaultProps = {
  masterCourse: {id: 17},
  canManageCourse: true,
  hasLoadedAssociations: true,
  isSavingAssociations: false,
  willSendNotification: false,
  isLoadingUnsyncedChanges: false,
  hasLoadedUnsyncedChanges: true,
  unsyncedChanges: sampleData.unsyncedChanges,
  migrationStatus: MigrationStates.states.unknown,
  isLoadingBeginMigration: false,
  existingAssociations: sampleData.courses,
  addedAssociations: [],
  removedAssociations: [],
}
const actionProps = {
  loadAssociations: noop,
  saveAssociations: noop,
  clearAssociations: noop,
  enableSendNotification: noop,
  loadUnsyncedChanges: noop,
}

function mockStore (props = {...defaultProps}) {
  return createStore({...props})
}

function connect (props = {...defaultProps}) {
  const store = mockStore(props)
  return (
    <Provider store={store}>
      <ConnectedCourseSidebar {...props} {...actionProps} />
    </Provider>
  )
}

QUnit.module('Course Sidebar component', {
  setup () {
    sidebarContentRef = null
    moxios.install()
    moxios.stubRequest('/api/v1/courses/4/blueprint_templates/default/migrations', {
      status: 200,
      response: [{id: '1'}]
    })
  },
  teardown () {
    moxios.uninstall()
  }
})

test('renders the closed CourseSidebar component', () => {
  const tree = enzyme.mount(connect())
  const node = tree.find('button')
  equal(node.text().trim(), 'Open sidebar')
})

test('renders the open CourseSidebar component', () => {
  const contentRef = (cr) => { sidebarContentRef = cr }
  const props = {...defaultProps}
  props.contentRef = contentRef
  const tree = enzyme.mount(connect(props))
  tree.find('button').simulate('click')
  ok(sidebarContentRef, 'sidebar contents')
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)
  const rows = sidebar.find('.bcs__row')

  // associations
  ok(rows.at(0).find('button#mcSidebarAsscBtn').exists(), 'Associations button')
  equal(rows.at(0).text().trim(), `Associations${props.existingAssociations.length}`, 'Associations count')

  // sync history
  ok(rows.at(1).find('button#mcSyncHistoryBtn').exists(), 'sync history button')

  // unsynced changes
  ok(rows.at(2).find('button#mcUnsyncedChangesBtn').exists(), 'unsynced changes button')
  equal(rows.at(2).find('span').at(0).text(), 'Unsynced Changes')
  equal(rows.at(2).find('span').at(1).text(), props.unsyncedChanges.length, 'unsynced changes count')
})

test('renders no Uncynced Changes link if there are none', () => {
  const contentRef = (cr) => { sidebarContentRef = cr }
  const props = {...defaultProps}
  props.contentRef = contentRef
  props.unsyncedChanges = []
  const tree = enzyme.mount(connect(props))
  tree.find('button').simulate('click')
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  // no unsynced changes
  notOk(sidebar.find('button#mcUnsyncedChangesBtn').exists())
})

test('renders no Associations link if the user not an admin', () => {
  const contentRef = (cr) => { sidebarContentRef = cr }
  const props = {...defaultProps}
  props.contentRef = contentRef
  props.canManageCourse = false
  const tree = enzyme.mount(connect(props))
  tree.find('button').simulate('click')
  ok(sidebarContentRef)
  const sidebar = new enzyme.ReactWrapper(sidebarContentRef, sidebarContentRef)

  // no unsynced changes
  notOk(sidebar.find('button#mcSidebarAsscBtn').exists())
})
