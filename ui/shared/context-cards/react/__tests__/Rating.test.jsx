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
import {mount} from 'enzyme'
import Rating from '../Rating'
import {Rating as InstUIRating} from '@instructure/ui-rating'

describe('StudentContextTray/Rating', () => {
  let subject
  const participationsLevel = 2

  describe('formatValueText', () => {
    beforeEach(() => {
      subject = mount(<Rating label="whatever" metric={{level: 1}} />)
    })

    const valueText = ['None', 'Low', 'Moderate', 'High']
    valueText.forEach((v, i) => {
      it(`returns value ${v} for rating ${i}`, () => {
        expect(subject.instance().formatValueText(i, 3)).toEqual(v)
      })
    })
  })

  describe('render', () => {
    it('delegates to InstUIRating', () => {
      subject = mount(
        <Rating
          label="Participation"
          metric={{
            level: participationsLevel,
          }}
        />
      )
      const instUIRating = subject.find(InstUIRating)
      expect(instUIRating.props().label).toEqual(subject.props().label)
    })
  })
})
