/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import {mount} from 'enzyme'
import File from 'compiled/models/File'
import DragFeedback from 'jsx/files/DragFeedback'

QUnit.module('DragFeedback')

test('DF: shows a badge with number of items being dragged', () => {
  const file = new File({id: 1, name: 'Test File', thumbnail_url: 'blah'})
  const file2 = new File({id: 2, name: 'Test File 2', thumbnail_url: 'blah'})
  file.url = () => 'some_url'
  file2.url = () => 'some_url'

  const dragFeedback = mount(
    <DragFeedback pageX={1} pageY={1} itemsToDrag={[file, file2]} />
  )

  equal(
    dragFeedback.find('.badge').instance().innerHTML,
    '2',
    'has two items'
  )
})
