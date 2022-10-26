/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import Helpers from 'ui/features/course_settings/react/helpers'

QUnit.module('Course Settings Helpers')

test('isValidImageType', () => {
  ok(Helpers.isValidImageType('image/jpeg'), 'accepts jpeg')
  ok(Helpers.isValidImageType('image/gif'), 'accepts gif')
  ok(Helpers.isValidImageType('image/png'), 'accepts png')
  ok(!Helpers.isValidImageType('image/tiff'), 'denies tiff')
})

test('extractInfoFromEvent', () => {
  const changeEvent = {
    type: 'change',
    target: {
      files: [{type: 'image/jpeg'}],
    },
  }

  const dragEvent = {
    type: 'drop',
    dataTransfer: {
      files: [
        {
          name: 'test',
          type: 'image/jpeg',
        },
      ],
    },
  }

  const changeResults = Helpers.extractInfoFromEvent(changeEvent)
  const expectedChangeResults = {
    file: {
      type: 'image/jpeg',
    },
    type: 'image/jpeg',
  }

  const dragResults = Helpers.extractInfoFromEvent(dragEvent)
  const expectedDragResults = {
    file: {
      name: 'test',
      type: 'image/jpeg',
    },
    type: 'image/jpeg',
  }

  deepEqual(changeResults, expectedChangeResults, 'creates the proper info from change events')
  deepEqual(dragResults, expectedDragResults, 'creates the proper info from drag events')
})
