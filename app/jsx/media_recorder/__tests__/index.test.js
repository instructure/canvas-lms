/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import '@instructure/ui-themes/lib/canvas'
import React from 'react'
import {shallow} from 'enzyme'
import MediaRecorder from '../index'

const defaultProps = () => ({
  onSaveFile: () => {}
})

test('renders the MediaRecorder component', () => {
  const tree = shallow(<MediaRecorder {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('onSaveFile calls the correct prop', () => {
  const props = defaultProps()
  const onSaveSpy = jest.fn()
  props.onSaveFile = onSaveSpy;
  const tree = shallow(<MediaRecorder {...props} />)

  const FILE_NAME = "Blah blah blah file";
  tree.instance().saveFile(FILE_NAME);

  expect(onSaveSpy.mock.calls[0][0]).toMatch(FILE_NAME)
})

