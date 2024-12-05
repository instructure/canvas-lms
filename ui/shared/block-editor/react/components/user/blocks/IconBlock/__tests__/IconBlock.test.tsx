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
import {IconBlock, type IconBlockProps} from '..'

const renderBlock = (props: Partial<IconBlockProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{IconBlock}}>
      <Frame>
        <IconBlock iconName="idea" {...props} />
      </Frame>
    </Editor>
  )
}

describe('IconBlock', () => {
  it('should render with default props', () => {
    const {container, getByTitle} = renderBlock()

    const icon = container.querySelector('svg')
    expect(icon).toBeInTheDocument()
    expect(getByTitle('idea')).toBeInTheDocument()
    expect(icon).toHaveStyle({width: '1em', height: '1em', fontSize: '2rem'}) // small
  })

  it('should honor size prop', () => {
    const {container, getByTitle} = renderBlock({size: 'large'})

    const icon = container.querySelector('svg')
    expect(icon).toBeInTheDocument()
    expect(getByTitle('idea')).toBeInTheDocument()
    expect(icon).toHaveStyle({width: '1em', height: '1em', fontSize: '5rem'}) // large
  })

  it('should honor color prop', () => {
    const {container, getByTitle} = renderBlock({color: 'red'})

    const icon = container.querySelector('svg')
    expect(icon).toBeInTheDocument()
    expect(getByTitle('idea')).toBeInTheDocument()
    expect(document.querySelector('.icon-block')).toHaveStyle({color: 'red'})
  })
})
