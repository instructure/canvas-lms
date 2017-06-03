import React from 'react'
import * as enzyme from 'enzyme'
import EnableNotification from 'jsx/blueprint_courses/components/EnableNotification'
import MigrationStates from 'jsx/blueprint_courses/migrationStates'

const noop = () => {}

QUnit.module('EnableNotification component')

const defaultProps = {
  migrationStatus: MigrationStates.states.unknown,
  willSendNotification: false,
  willIncludeCustomNotificationMessage: false,
  notificationMessage: '',
  enableSendNotification: noop,
  includeCustomNotificationMessage: noop,
  setNotificationMessage: noop,
}

test('renders the EnableNotification component', () => {
  const tree = enzyme.shallow(<EnableNotification {...defaultProps} />)
  const node = tree.find('.bcs__history-notification')
  ok(node.exists())
})

test('renders the enable checkbox', () => {
  const tree = enzyme.mount(<EnableNotification {...defaultProps} />)
  const checkboxes = tree.find('input[type="checkbox"]')
  equal(checkboxes.length, 1)
  equal(checkboxes.node.checked, false)
})

test('renders the add a message checkbox', () => {
  const props = {...defaultProps}
  props.willSendNotification = true

  const tree = enzyme.mount(<EnableNotification {...props} />)
  const checkboxes = tree.find('Checkbox')
  equal(checkboxes.length, 2)
  equal(checkboxes.nodes[0].checked, true)
  equal(checkboxes.nodes[1].checked, false)
  const messagebox = tree.find('TextArea')
  ok(!messagebox.exists())
})

test('renders the message text area', () => {
  const props = {...defaultProps}
  props.willSendNotification = true
  props.willIncludeCustomNotificationMessage = true

  const tree = enzyme.mount(<EnableNotification {...props} />)
  const checkboxes = tree.find('Checkbox')
  equal(checkboxes.length, 2)
  equal(checkboxes.nodes[0].checked, true)
  equal(checkboxes.nodes[1].checked, true)
  const messagebox = tree.find('TextArea')
  ok(messagebox.exists())
})
