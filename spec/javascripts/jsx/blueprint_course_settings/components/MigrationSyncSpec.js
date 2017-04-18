import React from 'react'
import * as enzyme from 'enzyme'
import MigrationSync from 'jsx/blueprint_course_settings/components/MigrationSync'

QUnit.module('MigrationSync component')

const defaultProps = () => ({
  migrationStatus: 'void',
  hasCheckedMigration: true,
  isLoadingBeginMigration: false,
  checkMigration: () => {},
  beginMigration: () => {},
})

test('renders the MigrationSync component', () => {
  const tree = enzyme.shallow(<MigrationSync {...defaultProps()} />)
  const node = tree.find('.bcs__migration-sync')
  ok(node.exists())
})

test('renders the progress indicator if in a loading migration state', () => {
  const props = defaultProps()
  props.migrationStatus = 'queued'
  const tree = enzyme.shallow(<MigrationSync {...props} />)
  const node = tree.find('.bcs__migration-sync__loading')
  ok(node.exists())
})

test('renders the progress indicator if in the process of beginning a migration', () => {
  const props = defaultProps()
  props.isLoadingBeginMigration = true
  const tree = enzyme.shallow(<MigrationSync {...props} />)
  const node = tree.find('.bcs__migration-sync__loading')
  ok(node.exists())
})

test('calls beginMigration when sync button is clicked', () => {
  const props = defaultProps()
  props.beginMigration = sinon.spy()
  const tree = enzyme.mount(<MigrationSync {...props} />)
  const button = tree.find('.bcs__migration-sync button')
  button.at(0).simulate('click')
  equal(props.beginMigration.callCount, 1)
})

test('calls checkMigration on mount if it has not been checked already', () => {
  const props = defaultProps()
  props.hasCheckedMigration = false
  props.checkMigration = sinon.spy()
  const tree = enzyme.shallow(<MigrationSync {...props} />) // eslint-disable-line
  equal(props.checkMigration.callCount, 1)
})

test('does not call checkMigration on mount if it has been checked already', () => {
  const props = defaultProps()
  props.hasCheckedMigration = true
  props.checkMigration = sinon.spy()
  const tree = enzyme.shallow(<MigrationSync {...props} />) // eslint-disable-line
  equal(props.checkMigration.callCount, 0)
})
