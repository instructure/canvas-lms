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
import Text from '@instructure/ui-elements/lib/components/Text'
import IconWarningLine from '@instructure/ui-icons/lib/Line/IconWarning'
import IconInfoLine from '@instructure/ui-icons/lib/Line/IconInfo'
import Message from 'jsx/gradezilla/default_gradebook/components/SubmissionStatus/Message'

QUnit.module('Message', () => {
  QUnit.module('variant warning', () => {
    test('includes IconWarningLine with message', () => {
      const message = 'Some Message'
      const wrapper = shallow(<Message variant="warning" message={message} />)
      strictEqual(wrapper.containsMatchingElement(<IconWarningLine />), true)
    })

    test('includes a text message', () => {
      const message = 'Some Message'
      const wrapper = shallow(<Message variant="warning" message={message} />)
      strictEqual(wrapper.contains(<Text color="warning" size="small">{message}</Text>), true)
    })
  })

  QUnit.module('variant info', () => {
    test('includes IconWarningLine with message', () => {
      const message = 'Some Message'
      const wrapper = shallow(<Message variant="info" message={message} />)
      strictEqual(wrapper.containsMatchingElement(<IconInfoLine />), true)
    })

    test('includes a text message', () => {
      const message = 'Some Message'
      const wrapper = shallow(<Message variant="info" message={message} />)
      strictEqual(wrapper.contains(<Text color="primary" size="small">{message}</Text>), true)
    })
  })
})
