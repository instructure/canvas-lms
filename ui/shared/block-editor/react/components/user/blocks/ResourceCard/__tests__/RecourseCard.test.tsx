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
import userEvent from '@testing-library/user-event'
import {Editor, Frame} from '@craftjs/core'
import {TextBlock} from '../../TextBlock'
import {HeadingBlock} from '../../HeadingBlock'
import {IconBlock} from '../../IconBlock'
import {ButtonBlock} from '../../ButtonBlock'
import {ResourceCard, type ResourceCardProps} from '..'

const renderBlock = (enabled: boolean, props: Partial<ResourceCardProps> = {}) => {
  return render(
    <Editor
      enabled={enabled}
      resolver={{TextBlock, HeadingBlock, IconBlock, ButtonBlock, ResourceCard}}
    >
      <Frame>
        <ResourceCard {...props} />
      </Frame>
    </Editor>,
  )
}

describe('ResourceCard', () => {
  it('should render default props', () => {
    const {getByText, getByTitle} = renderBlock(true)
    expect(getByTitle('apple')).toBeInTheDocument()
    expect(getByText('Title')).toBeInTheDocument()
    expect(getByText('Description')).toBeInTheDocument()
    expect(getByText('Link')).toBeInTheDocument()
  })

  it('should render given props', () => {
    const {getByText, getByTitle} = renderBlock(true, {
      id: 'myId',
      title: 'My Title',
      description: 'My Description',
      iconName: 'calendar',
      linkText: 'My Link',
      linkUrl: 'https://example.com',
    })

    expect(getByTitle('calendar')).toBeInTheDocument()
    expect(getByText('My Title')).toBeInTheDocument()
    expect(getByText('My Description')).toBeInTheDocument()
    expect(getByText('My Link')).toBeInTheDocument()
    expect(getByText('My Link').closest('a')).toHaveAttribute('href', 'https://example.com')
  })

  // test RescourceCard.craft.custom.isDeletable either in RecourcesSection or selenium
})
