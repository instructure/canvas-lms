/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import Rating from '../Rating'
import {render} from '@testing-library/react'

describe('StudentContextTray/Rating', () => {
  const participationsLevel = 2

  describe('formatValueText', () => {
    const ref = React.createRef()
    beforeEach(() => {
      render(<Rating label="whatever" metric={{level: 1}} ref={ref} />)
    })

    const valueText = ['None', 'Low', 'Moderate', 'High']
    valueText.forEach((v, i) => {
      it(`returns value ${v} for rating ${i}`, () => {
        expect(ref.current.formatValueText(i, 3)).toEqual(v)
      })
    })
  })

  describe('render', () => {
    it('delegates to InstUIRating', () => {
      const label = 'Participation'
      const formatedValueText = 'Moderate'

      const wrapper = render(
        <Rating
          label={label}
          metric={{
            level: participationsLevel,
          }}
        />
      )
      expect(wrapper.queryByText(`${label} ${formatedValueText}`)).toBeInTheDocument()
    })
  })
})
