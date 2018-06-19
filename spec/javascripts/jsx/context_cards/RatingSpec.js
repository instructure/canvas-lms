/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import TestUtils from 'react-addons-test-utils'
import Rating from 'jsx/context_cards/Rating'
import InstUIRating from '@instructure/ui-core/lib/components/Rating'

QUnit.module('StudentContextTray/Rating', () => {
  let subject
  const participationsLevel = 2

  QUnit.module('formatValueText', hooks => {
    hooks.beforeEach(() => {
      subject = TestUtils.renderIntoDocument(
        <Rating metric={{level: 1}} />
      )
    })

    const valueText = [
      'None', 'Low', 'Moderate', 'High'
    ]
    valueText.forEach((v, i) => {
      test(`returns value ${v} for rating ${i}`, () => {
        equal(subject.formatValueText(i, 3), v)
      })
    })
  })

  QUnit.module('render', () => {
    test('delegates to InstUIRating', () => {
      subject = TestUtils.renderIntoDocument(
        <Rating
          label='Participation'
          metric={{
            level: participationsLevel
          }}
        />
      )
      const instUIRating = TestUtils.findRenderedComponentWithType(subject, InstUIRating)
      equal(instUIRating.props.label, subject.props.label)
    })
  })
})
