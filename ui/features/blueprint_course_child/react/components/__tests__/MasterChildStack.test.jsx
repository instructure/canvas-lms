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
import {shallow} from 'enzyme'
import MasterChildStack from '../MasterChildStack'
import getSampleData from '@canvas/blueprint-courses/getSampleData'

describe('MasterChildStack component', () => {
  const defaultProps = () => ({
    child: getSampleData().childCourse,
    master: getSampleData().masterCourse,
    terms: getSampleData().terms,
  })

  test('renders the MasterChildStack component', () => {
    const tree = shallow(<MasterChildStack {...defaultProps()} />)
    const node = tree.find('.bcc__master-child-stack')
    expect(node.exists()).toBeTruthy()
  })

  test('renders two boxes', () => {
    const tree = shallow(<MasterChildStack {...defaultProps()} />)
    const nodes = tree.find('.bcc__master-child-stack__box')
    expect(nodes).toHaveLength(2)
  })

  test('renders the first box as a master box', () => {
    const tree = shallow(<MasterChildStack {...defaultProps()} />)
    const node = tree.find('.bcc__master-child-stack__box').at(0)
    expect(node.hasClass('bcc__master-child-stack__box__master')).toBeTruthy()
  })
})
