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
import BlueprintSidebar from 'jsx/blueprint_courses/components/BlueprintSidebar'

QUnit.module('BlueprintSidebar component')

const defaultProps = () => ({

})

test('renders the BlueprintSidebar component', () => {
  const tree = enzyme.shallow(<BlueprintSidebar {...defaultProps()} />)
  const node = tree.find('.bcs__wrapper')
  ok(node.exists())
})

test('clicking open button sets isOpen to true', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<BlueprintSidebar {...props} />)

  const button = tree.find('.bcs__trigger button')
  button.at(0).simulate('click')

  const instance = tree.instance()
  equal(instance.state.isOpen, true)
  tree.unmount()
})

test('clicking close button sets isOpen to false', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<BlueprintSidebar {...props} />)

  const instance = tree.instance()
  instance.setState({ isOpen: true })

  const closeBtn = instance.closeBtn
  const btnWrapper = new enzyme.ReactWrapper(closeBtn, closeBtn)
  btnWrapper.at(0).simulate('click')

  equal(instance.state.isOpen, false)
  tree.unmount()
})
