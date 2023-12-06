/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {attachImmersiveReaderButton} from '../utils'
import {initializeReaderButton} from '@canvas/immersive-reader/ImmersiveReader'

jest.mock('@canvas/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: jest.fn(),
  }
})

const CUSTOM_CONTENT = '<p>Some custom syllabus text</p>'

describe('attachImmersiveReaderButton', () => {
  beforeAll(() => {
    const div = document.createElement('div')
    div.id = 'course_syllabus'
    div.innerHTML = CUSTOM_CONTENT
    document.body.appendChild(div)
  })

  it('sends the content from the #course_syllabus node', () => {
    const mountNode = document.createElement('div')
    mountNode.id = 'immersive_reader_mount_node'
    document.body.appendChild(mountNode)

    attachImmersiveReaderButton([mountNode])

    const content = initializeReaderButton.mock.calls[0][1].content
    expect(content()).toEqual(CUSTOM_CONTENT)
  })
})
