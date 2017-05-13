import React from 'react'
import * as enzyme from 'enzyme'
import LockToggle from 'jsx/blueprint_courses/lockToggle'

QUnit.module('LockToggle component')

const defaultProps = () => ({
  isLocked: true,
  isToggleable: true,
})

test('renders the LockToggle component', () => {
  const tree = enzyme.shallow(<LockToggle {...defaultProps()} />)
  const node = tree.find('.bpc-lock-toggle')
  ok(node.exists())
})

test('renders a button when LockToggle is toggleable', () => {
  const props = defaultProps()
  props.isToggleable = true
  const tree = enzyme.mount(<LockToggle {...props} />)
  const node = tree.find('Button')
  ok(node.exists())
})

test('does not render a button when LockToggle is not toggleable', () => {
  const props = defaultProps()
  props.isToggleable = false
  const tree = enzyme.shallow(<LockToggle {...props} />)
  const node = tree.find('Button')
  notOk(node.exists())
})

test('renders a locked icon when LockToggle is locked', () => {
  const props = defaultProps()
  props.isLocked = true
  const tree = enzyme.shallow(<LockToggle {...props} />)
  const node = tree.find('IconLockSolid')
  ok(node.exists())
})

test('renders an unlocked icon when LockToggle is unlocked', () => {
  const props = defaultProps()
  props.isLocked = false
  const tree = enzyme.shallow(<LockToggle {...props} />)
  const node = tree.find('IconUnlockSolid')
  ok(node.exists())
})
