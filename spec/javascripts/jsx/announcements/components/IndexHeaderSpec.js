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
import { mount } from 'enzyme'
import _ from 'lodash'

import IndexHeader from 'jsx/announcements/components/IndexHeader'

const makeProps = (props = {}) => _.merge({
  courseId: '5',
  permissions: {
    create: true,
    manage_content: true,
    moderate: true,
  },
}, props)

QUnit.module('IndexHeader component')

test('renders the component', () => {
  const tree = mount(<IndexHeader {...makeProps()} />)
  const node = tree.find('IndexHeader')
  ok(node.exists())
})

test('renders create announcement button if we have create permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { create: true } })} />
  )
  const node = tree.find('#add_announcement')
  ok(node.exists())
})

test('does not render create announcement button if we do not have create permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { create: false } })} />
  )
  const node = tree.find('#add_announcement')
  notOk(node.exists())
})