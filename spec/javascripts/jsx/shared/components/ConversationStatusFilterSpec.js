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
import { shallow } from 'enzyme'
import _ from 'lodash'
import ConversationStatusFilter from 'jsx/shared/components/ConversationStatusFilter'

QUnit.module('ConversationStatusFilter component')

const makeProps = (props = {}) => _.merge({
  filters: [
    { value: 'inbox', label: 'Inbox' },
    { value: 'unread', label: 'Unread' },
    { value: 'sent', label: 'Sent' }
  ],
  defaultFilter: 'inbox',
  initialFilter: null,
  onChange: () => {}
}, props)

test('default initial selected option', () => {
  const wrapper1 = shallow(<ConversationStatusFilter {...makeProps()} />)
  strictEqual(wrapper1.state().selected, 'inbox')

  const wrapper2 = shallow(<ConversationStatusFilter {...makeProps({ initialFilter: 'unread' })} />)
  strictEqual(wrapper2.state().selected, 'unread')

  const wrapper3 = shallow(<ConversationStatusFilter {...makeProps({ initialFilter: 'invalid' })} />)
  strictEqual(wrapper3.state().selected, 'inbox')
})
