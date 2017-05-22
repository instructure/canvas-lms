import React from 'react'
import * as enzyme from 'enzyme'
import SyncHistory from 'jsx/blueprint_courses/components/SyncHistory'

QUnit.module('SyncHistory component')

const defaultProps = () => ({
  loadHistory: () => {},
  isLoadingHistory: false,
  hasLoadedHistory: false,
  loadAssociations: () => {},
  isLoadingAssociations: false,
  hasLoadedAssociations: false,
})

test('renders the SyncHistory component', () => {
  const tree = enzyme.shallow(<SyncHistory {...defaultProps()} />)
  const node = tree.find('.bcs__history')
  ok(node.exists())
})

test('displays spinner when loading courses', () => {
  const props = defaultProps()
  props.isLoadingHistory = true
  const tree = enzyme.shallow(<SyncHistory {...props} />)
  const node = tree.find('.bcs__history Spinner')
  ok(node.exists())
})
