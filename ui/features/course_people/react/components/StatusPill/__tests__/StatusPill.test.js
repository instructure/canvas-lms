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

import {render} from '@testing-library/react'
import React from 'react'
import StatusPill, {ACTIVE_STATE, INACTIVE_STATE, PENDING_STATE, PILL_MAP} from '../StatusPill'

describe('StatusPill', () => {
  const setup = state => {
    return render(<StatusPill state={state} />)
  }

  describe('Test when status is inactive', () => {
    it('should render', () => {
      const container = setup(INACTIVE_STATE)
      expect(container).toBeTruthy()
    })

    it('should have pill text', () => {
      const container = setup(INACTIVE_STATE)
      const pillText = PILL_MAP[INACTIVE_STATE].text
      expect(container.getByText(pillText)).toBeInTheDocument()
    })

    it('should have hint text', () => {
      const container = setup(INACTIVE_STATE)
      const hintText = PILL_MAP[INACTIVE_STATE].hintText
      expect(container.getByText(hintText)).toBeInTheDocument()
    })
  })

  describe('Test when status is pending', () => {
    it('should render when status is pending', () => {
      const container = setup(PENDING_STATE)
      expect(container).toBeTruthy()
    })

    it('should have pill text', () => {
      const container = setup(PENDING_STATE)
      const pillText = PILL_MAP[PENDING_STATE].text
      expect(container.getByText(pillText)).toBeInTheDocument()
    })

    it('should have hint text', () => {
      const container = setup(PENDING_STATE)
      const hintText = PILL_MAP[PENDING_STATE].hintText
      expect(container.getByText(hintText)).toBeInTheDocument()
    })
  })

  it('should not render any content when status is active', () => {
    const container = setup(ACTIVE_STATE)
    expect(container.queryAllByText(/.+/i)).toHaveLength(0)
  })
})
