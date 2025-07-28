/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {Editor, Frame} from '@craftjs/core'
import {NoSections, type NoSectionsProps} from '../NoSections'

const renderBlock = (props: Partial<NoSectionsProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{NoSections}}>
      <Frame>
        <NoSections {...props} />
      </Frame>
    </Editor>,
  )
}

describe('NoSections', () => {
  it('should render with default props', () => {
    const {container} = renderBlock()

    const placeholder = container.querySelector('.no-sections')?.getAttribute('data-placeholder')

    expect(placeholder).toBe('Drop a block to add it here')
  })

  it('should honor className prop', () => {
    const {container} = renderBlock({className: 'test-class'})

    const clazz = container.querySelector('.no-sections')?.getAttribute('class')

    expect(clazz).toContain('test-class')
  })

  it('should render its children', () => {
    const {getByText} = renderBlock({children: <div>Test</div>})

    expect(getByText('Test')).toBeInTheDocument()
  })

  describe('craft.rules.canMoveIn', () => {
    it('should not allow a section to be moved into it', () => {
      renderBlock()

      const can = NoSections.craft.rules.canMoveIn([
        // @ts-expect-error
        {data: {custom: {isSection: true}}},
      ])
      expect(can).toBe(false)
    })

    it('should allow a non-section to be moved into it', () => {
      renderBlock()

      const can = NoSections.craft.rules.canMoveIn([
        // @ts-expect-error
        {data: {custom: {isSection: false}}},
      ])
      expect(can).toBe(true)
    })

    it('should not allow any section to be moved into it', () => {
      renderBlock()

      const can = NoSections.craft.rules.canMoveIn([
        // @ts-expect-error
        {data: {custom: {isSection: false}}},
        // @ts-expect-error
        {data: {custom: {isSection: true}}},
      ])
      expect(can).toBe(false)
    })
  })
})
