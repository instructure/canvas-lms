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
import {ButtonBlock, type ButtonBlockProps} from '../ButtonBlock'

const renderBlock = (props: Partial<ButtonBlockProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{ButtonBlock}}>
      <Frame>
        <ButtonBlock text="A Button" {...props} />
      </Frame>
    </Editor>
  )
}

describe('ButtonBlock', () => {
  it('should render with default props', () => {
    const {getByText} = renderBlock()
    expect(getByText('A Button')).toBeInTheDocument()

    // this gets into the instui implementation of things
    // but it's the only way I can think of to test the effect
    // of props on the style of the rendered component
    const btn = getByText('A Button').closest('a') as HTMLAnchorElement
    const firstSpan = btn.querySelector('span')
    expect(firstSpan).toHaveStyle({fontSize: '1rem'}) // medium
    expect(firstSpan).toHaveStyle({backgroundColor: '--var(ic-brand-primary)'})
    expect(firstSpan).toHaveStyle({paddingLeft: '0.75rem'})
    expect(btn.querySelector('svg')).not.toBeInTheDocument()
  })

  it('accepts a size prop', () => {
    const {getByText} = renderBlock({size: 'large'})
    const btn = getByText('A Button').closest('a') as HTMLAnchorElement
    const firstSpan = btn.querySelector('span')
    expect(firstSpan).toHaveStyle({fontSize: '1.375rem'})
  })

  it('accepts an href prop', () => {
    const {getByText} = renderBlock({href: 'https://example.com'})
    const btn = getByText('A Button').closest('a')
    expect(btn?.getAttribute('href')).toBe('https://example.com')
  })

  it('accepts the condensed variant prop', () => {
    const {getByText} = renderBlock({variant: 'condensed'})
    const btn = getByText('A Button').closest('a') as HTMLAnchorElement
    const firstSpan = btn.querySelector('span')
    expect(firstSpan).toHaveStyle({backgroundColor: 'transparent'})
    expect(firstSpan).toHaveStyle({paddingLeft: '0px'})
  })

  it('accepts the outlined variant prop', () => {
    const {getByText} = renderBlock({variant: 'outlined'})
    const btn = getByText('A Button').closest('a') as HTMLAnchorElement
    const firstSpan = btn.querySelector('span')
    expect(firstSpan).toHaveStyle({backgroundColor: 'transparent'})
    expect(firstSpan).toHaveStyle({paddingLeft: '0.75rem'})
  })

  it('accepts a standard button color prop', () => {
    const {getByText} = renderBlock({color: 'success'})
    const btn = getByText('A Button').closest('a') as HTMLAnchorElement
    const firstSpan = btn.querySelector('span')
    expect(firstSpan).toHaveStyle({backgroundColor: '--var(ic-brand-success)'})
  })

  it('accepts a custom color prop', () => {
    const {getByText} = renderBlock({color: '#ff0000'})
    const btn = getByText('A Button').closest('a') as HTMLAnchorElement
    const firstSpan = btn.querySelector('span')
    expect(firstSpan).toHaveStyle({backgroundColor: '#ff0000'})
  })

  it('accepts an icon prop', () => {
    const {getByText} = renderBlock({iconName: 'alarm'})
    const btn = getByText('A Button').closest('a') as HTMLAnchorElement
    const icon = btn.querySelector('svg')
    expect(icon).toBeInTheDocument()
  })
})
