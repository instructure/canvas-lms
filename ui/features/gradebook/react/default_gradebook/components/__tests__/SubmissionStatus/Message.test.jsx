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
import {shallow} from 'enzyme'
import {Text} from '@instructure/ui-text'
import {IconWarningLine, IconInfoLine} from '@instructure/ui-icons'
import Message from '../../SubmissionStatus/Message'

describe('Message', () => {
  describe('variant warning', () => {
    test('includes IconWarningLine with message', () => {
      const message = 'Some Message'
      const wrapper = shallow(<Message variant="warning" message={message} />)
      expect(wrapper.containsMatchingElement(<IconWarningLine />)).toBe(true)
    })

    test('includes a text message', () => {
      const message = 'Some Message'
      const wrapper = shallow(<Message variant="warning" message={message} />)
      expect(
        wrapper.contains(
          <Text color="danger" size="small">
            {message}
          </Text>
        )
      ).toBe(true)
    })
  })

  describe('variant info', () => {
    test('includes IconInfoLine with message', () => {
      const message = 'Some Message'
      const wrapper = shallow(<Message variant="info" message={message} />)
      expect(wrapper.containsMatchingElement(<IconInfoLine />)).toBe(true)
    })

    test('includes a text message', () => {
      const message = 'Some Message'
      const wrapper = shallow(<Message variant="info" message={message} />)
      expect(
        wrapper.contains(
          <Text color="primary" size="small">
            {message}
          </Text>
        )
      ).toBe(true)
    })
  })
})
