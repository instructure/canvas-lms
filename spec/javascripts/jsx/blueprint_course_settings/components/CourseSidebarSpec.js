import React from 'react'
import * as enzyme from 'enzyme'
import CourseSidebar from 'jsx/blueprint_course_settings/components/CourseSidebar'
import MigrationStates from 'jsx/blueprint_course_settings/migrationStates'
import sampleData from '../sampleData'

const noop = () => {}

const defaultProps = () => ({
  hasLoadedAssociations: false,
  associations: sampleData.courses,
  loadAssociations: noop,
  saveAssociations: noop,
  clearAssociations: noop,
  hasAssociationChanges: true,
  isSavingAssociations: false,
  willSendNotification: false,
  enableSendNotification: noop,
  loadUnsynchedChanges: noop,
  isLoadingUnsynchedChanges: false,
  hasLoadedUnsynchedChanges: true,
  unsynchedChanges: sampleData.unsynchedChanges,
  migrationStatus: MigrationStates.unknown
})

QUnit.module('CourseSidebar component')

test('renders the CourseSidebar component', () => {
  const tree = enzyme.shallow(<CourseSidebar {...defaultProps()} />)
  const rows = tree.find('.bcs__row')
  equal(rows.length, 4)
})
