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
import * as enzyme from 'enzyme'
import BlueprintModal from 'jsx/blueprint_courses/components/BlueprintModal'

QUnit.module('BlueprintModal component', {
  setup () {
    const appElement = document.createElement('div')
    appElement.id = 'application'
    document.getElementById('fixtures').appendChild(appElement)
  },

  teardown () {
    document.getElementById('fixtures').innerHTML = ''
  }
})

const defaultProps = () => ({
  isOpen: true,
})

const render = (props = defaultProps(), children = <p>content</p>) => (
  <BlueprintModal {...props}>{children}</BlueprintModal>
)

test('renders the BlueprintModal component', () => {
  const tree = enzyme.shallow(render())
  const node = tree.find('Modal')
  ok(node.exists())
  tree.unmount()
})

test('renders the Done button when there are no changes', () => {
  const wrapper = enzyme.mount(render())
  const modal = wrapper.instance()
  const footer = new enzyme.ReactWrapper(modal.footer, modal.footer)
  const buttons = footer.find('button')
  equal(buttons.length, 1)
  equal(buttons.at(0).text(), 'Done')
  wrapper.unmount()
})

test('renders the Save + Cancel buttons when there are changes', () => {
  const props = {
    ...defaultProps(),
    hasChanges: true,
  }
  const wrapper = enzyme.mount(render(props))
  const modal = wrapper.instance()
  const footer = new enzyme.ReactWrapper(modal.footer, modal.footer)
  const buttons = footer.find('button')
  equal(buttons.length, 2)
  equal(buttons.at(0).text(), 'Cancel')
  equal(buttons.at(1).text(), 'Save')
  wrapper.unmount()
})

test('renders the Done button when there are changes, but is in the process of saving', () => {
  const props = {
    ...defaultProps(),
    hasChanges: true,
    isSaving: true,
  }
  const wrapper = enzyme.mount(render(props))
  const modal = wrapper.instance()
  const footer = new enzyme.ReactWrapper(modal.footer, modal.footer)
  const buttons = footer.find('button')
  equal(buttons.length, 1)
  equal(buttons.at(0).text(), 'Done')
  wrapper.unmount()
})
