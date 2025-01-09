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
import {Editor, Frame, type Node} from '@craftjs/core'

import {PageBlock} from '..'

const renderBlock = (children: React.ReactNode | null = null) => {
  return render(
    <Editor enabled={true} resolver={{PageBlock}}>
      <Frame>
        <PageBlock>{children}</PageBlock>
      </Frame>
    </Editor>,
  )
}

describe('PageBlock', () => {
  it('renders', () => {
    const {container} = renderBlock()

    expect(container.querySelector('.block.page-block')).toBeInTheDocument()
  })

  it('renders its children', () => {
    const {container, getByText} = renderBlock(<div>Children</div>)

    expect(container.querySelector('.block.page-block')).toBeInTheDocument()
    expect(getByText('Children')).toBeInTheDocument()
  })

  describe('craftjs', () => {
    it('only permits sections as children', () => {
      // @ts-expect-error
      const fauxSection = {
        type: 'fauxSection',
        data: {
          custom: {
            isSection: true,
          },
        },
      } as Node
      const fauxSection2 = JSON.parse(JSON.stringify(fauxSection))
      expect(PageBlock.craft.rules.canMoveIn([fauxSection, fauxSection2])).toBe(true)

      fauxSection.data.custom.isSection = false
      expect(PageBlock.craft.rules.canMoveIn([fauxSection])).toBe(false)
    })
  })
})
