import React from 'react'
import * as enzyme from 'enzyme'
import SyncChange from 'jsx/blueprint_courses/components/SyncChange'
import data from '../sampleData'

QUnit.module('SyncChange component')

const defaultProps = () => ({
  change: data.history[0].changes[0],
})

test('renders the SyncChange component', () => {
  const tree = enzyme.shallow(<SyncChange {...defaultProps()} />)
  const node = tree.find('.bcs__history-item__change')
  ok(node.exists())
})

test('renders the SyncChange component expanded when state.isExpanded = true', () => {
  const props = defaultProps()
  props.isLoadingHistory = true
  const tree = enzyme.shallow(<SyncChange {...props} />)
  tree.instance().setState({ isExpanded: true })
  const node = tree.find('.bcs__history-item__change__expanded')
  ok(node.exists())
})

test('toggles isExpanded on click', () => {
  const props = defaultProps()
  props.isLoadingHistory = true
  const tree = enzyme.shallow(<SyncChange {...props} />)
  tree.at(0).simulate('click')

  const node = tree.find('.bcs__history-item__change__expanded')
  ok(node.exists())
})

test('displays the correct exception count', () => {
  const props = defaultProps()
  const tree = enzyme.shallow(<SyncChange {...props} />)
  const pill = tree.find('.pill')
  equal(pill.at(0).text(), '3 exceptions')
})
