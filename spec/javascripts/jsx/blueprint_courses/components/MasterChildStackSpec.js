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
import MasterChildStack from 'jsx/blueprint_courses/components/MasterChildStack'
import getSampleData from '../getSampleData'

QUnit.module('MasterChildStack component')

const defaultProps = () => ({
  child: getSampleData().childCourse,
  master: getSampleData().masterCourse,
  terms: getSampleData().terms,
})

test('renders the MasterChildStack component', () => {
  const tree = enzyme.shallow(<MasterChildStack {...defaultProps()} />)
  const node = tree.find('.bcc__master-child-stack')
  ok(node.exists())
})

test('renders two boxes', () => {
  const tree = enzyme.shallow(<MasterChildStack {...defaultProps()} />)
  const node = tree.find('.bcc__master-child-stack__box')
  ok(node.length, 2)
})

test('renders the first box as a master box', () => {
  const tree = enzyme.shallow(<MasterChildStack {...defaultProps()} />)
  const node = tree.find('.bcc__master-child-stack__box')
  ok(node.at(0).hasClass('bcc__master-child-stack__box__master'))
})
