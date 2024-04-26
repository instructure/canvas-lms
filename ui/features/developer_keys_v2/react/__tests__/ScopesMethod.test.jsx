/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import DeveloperKeyScopesMethod from '../ScopesMethod'

const baseProps = {
  method: 'get',
}

const defaultProps = props => ({
  ...baseProps,
  ...props,
})

const renderDeveloperKeyScopesMethod = props => {
  const ref = React.createRef()
  const wrapper = render(<DeveloperKeyScopesMethod ref={ref} {...defaultProps(props)} />)

  return {ref, wrapper}
}

describe('DeveloperKeyScopesMethod', () => {
  it('renders the correct method', () => {
    renderDeveloperKeyScopesMethod()

    expect(screen.getByText(new RegExp(baseProps.method, 'i'))).toBeInTheDocument()
  })

  describe('variant map', () => {
    it('maps GET to the primary variant', () => {
      const {ref} = renderDeveloperKeyScopesMethod()

      expect(ref.current.methodColorMap().get).toBe('primary')
    })

    it('maps PUT to the default variant', () => {
      const {ref} = renderDeveloperKeyScopesMethod()

      expect(ref.current.methodColorMap().put).toBe('default')
    })

    it('maps POST to the success variant', () => {
      const {ref} = renderDeveloperKeyScopesMethod()

      expect(ref.current.methodColorMap().post).toBe('success')
    })

    it('maps DELETE to the danger variant', () => {
      const {ref} = renderDeveloperKeyScopesMethod()

      expect(ref.current.methodColorMap().delete).toBe('danger')
    })
  })
})
