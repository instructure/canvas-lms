import React from 'react'
import * as enzyme from 'enzyme'
import LockBanner from 'jsx/blueprint_courses/lockBanner'

QUnit.module('LockBanner component')

const defaultProps = () => ({
  isLocked: true,
  itemLocks: {
    content: true,
    points: false,
    due_dates: false,
    availability_dates: false,
  },
})

test('renders an Alert when LockBanner is locked', () => {
  const props = defaultProps()
  props.isLocked = true
  const tree = enzyme.mount(<LockBanner {...props} />)
  const node = tree.find('Alert')
  ok(node.exists())
})

test('does not render Alert when LockBanner is locked', () => {
  const props = defaultProps()
  props.isLocked = false
  const tree = enzyme.mount(<LockBanner {...props} />)
  const node = tree.find('Alert')
  notOk(node.exists())
})

test('displays locked description text appropriately when one attribute is locked', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<LockBanner {...props} />)
  const text = tree.find('Typography').at(1).text()
  equal(text, 'Content')
})

test('displays locked description text appropriately when two attributes are locked', () => {
  const props = defaultProps()
  props.itemLocks.points = true
  const tree = enzyme.mount(<LockBanner {...props} />)
  const text = tree.find('Typography').at(1).text()
  equal(text, 'Content & Points')
})

test('displays locked description text appropriately when more than two attributes are locked', () => {
  const props = defaultProps()
  props.itemLocks.points = true
  props.itemLocks.due_dates = true
  const tree = enzyme.mount(<LockBanner {...props} />)
  const text = tree.find('Typography').at(1).text()
  equal(text, 'Content, Points & Due Dates')
})
