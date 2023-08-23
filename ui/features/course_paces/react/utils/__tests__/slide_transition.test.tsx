// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'

import SlideTransition from '../slide_transition'

const renderComponent = props =>
  render(
    <SlideTransition size={100} {...props}>
      <span>Hey look it&apos;s me!</span>
    </SlideTransition>
  )

describe('SlideTransition', () => {
  it('shows child components when expanded', () => {
    const {getByText} = renderComponent({direction: 'vertical', expanded: true})
    expect(getByText("Hey look it's me!")).toBeInTheDocument()
  })

  it('hides child components when collapsed', async () => {
    const {queryByText} = renderComponent({direction: 'vertical', expanded: false})
    await waitFor(() => expect(queryByText("Hey look it's me!")).not.toBeInTheDocument())
  })

  it('shrinks vertically when collapsed', () => {
    const {getByTestId} = renderComponent({direction: 'vertical', expanded: false})
    expect(getByTestId('course-paces-collapse')).toHaveStyle('max-height: 0')
  })

  it('restores height when expanded', () => {
    const {getByTestId} = renderComponent({direction: 'vertical', expanded: true})
    expect(getByTestId('course-paces-collapse')).toHaveStyle('max-height: 100px')
  })

  it('shrinks horizontally when collapsed', () => {
    const {getByTestId} = renderComponent({direction: 'horizontal', expanded: false})
    expect(getByTestId('course-paces-collapse')).toHaveStyle('width: 0px')
  })

  it('restores width when expanded', () => {
    const {getByTestId} = renderComponent({direction: 'horizontal', expanded: true})
    expect(getByTestId('course-paces-collapse')).toHaveStyle('width: 100px')
  })
})
