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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import {ConditionalTooltip} from '../ConditionalTooltip'

describe('ConditionalTooltip', () => {
  const subject = (overrideProps = {}) => {
    return render(
      <ConditionalTooltip
        condition={true}
        renderTip="explanation for something"
        on={['hover']}
        children={<p>child 1</p>} // eslint-disable-line react/no-children-prop
        {...overrideProps}
      />
    )
  }

  it('renders the tooltip when condition is true', () => {
    const {getByText} = subject()
    const tooltip = getByText('explanation for something')
    expect(tooltip).toBeInTheDocument()
  })

  it('does not render the tooltip when condition is false', () => {
    const {queryByText} = subject({condition: false})
    const tooltip = queryByText('explanation for something')
    expect(tooltip).not.toBeInTheDocument()
  })

  it('renders a child', () => {
    const {getByText} = subject()
    const child1 = getByText('child 1')
    expect(child1).toBeInTheDocument()
  })

  it('renders multiple children', () => {
    const {getByText} = subject({children: [<p key="1">child 1</p>, <p key="2">child 2</p>]})
    const child1 = getByText('child 1')
    const child2 = getByText('child 2')
    expect(child1).toBeInTheDocument()
    expect(child2).toBeInTheDocument()
  })

  it('tooltip is visible when hovered', () => {
    const {getByText} = subject()
    const tooltip = getByText('explanation for something')
    fireEvent.mouseOver(tooltip)
    expect(tooltip).toBeVisible()
  })
})
