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

import _ from 'lodash'
import ConversationStatusFilter from 'ui/features/conversations/react/ConversationStatusFilter'
import React from 'react'
import {shallow} from 'enzyme'

QUnit.module('ConversationStatusFilter component')

const makeProps = (props = {}) =>
  _.merge(
    {
      router: {
        on: () => {},
        off: () => {},
        header: {changeTypeFilter: _newState => {}},
      },
      defaultFilter: 'foo',
      initialFilter: 'foo',
      filters: {
        foo: 'foo',
        bar: 'bar',
        baz: 'baz',
      },
    },
    props
  )

test('default initial selected option', () => {
  const wrapper1 = shallow(<ConversationStatusFilter {...makeProps()} />)
  strictEqual(wrapper1.state().selected, 'foo')

  const wrapper2 = shallow(<ConversationStatusFilter {...makeProps({initialFilter: 'bar'})} />)
  strictEqual(wrapper2.state().selected, 'bar')
})

test('getUrlFilter accepts valid filters', () => {
  const wrapper = shallow(<ConversationStatusFilter {...makeProps()} />)
  strictEqual(wrapper.instance().getUrlFilter('type=foo'), 'foo')
  strictEqual(wrapper.instance().getUrlFilter('type=bar'), 'bar')
  strictEqual(wrapper.instance().getUrlFilter('type=baz'), 'baz')
  strictEqual(wrapper.instance().getUrlFilter('jar=jar&type=foo'), 'foo')
  strictEqual(wrapper.instance().getUrlFilter('jar=jar&type=bar'), 'bar')
  strictEqual(wrapper.instance().getUrlFilter('jar=jar&type=baz'), 'baz')
})

test('getUrlFilter uses defaults when invalid', () => {
  const wrapper1 = shallow(<ConversationStatusFilter {...makeProps()} />)
  strictEqual(wrapper1.instance().getUrlFilter('type=NOT_A_VALID_FILTER'), 'foo')
  strictEqual(wrapper1.instance().getUrlFilter('jar=jar&type=NOT_A_VALID_FILTER'), 'foo')
  strictEqual(wrapper1.instance().getUrlFilter(''), 'foo')
  strictEqual(wrapper1.instance().getUrlFilter('jar=jar'), 'foo')

  const wrapper2 = shallow(<ConversationStatusFilter {...makeProps({defaultFilter: 'bar'})} />)
  strictEqual(wrapper2.instance().getUrlFilter('type=NOT_A_VALID_FILTER'), 'bar')
  strictEqual(wrapper2.instance().getUrlFilter('jar=jar&type=NOT_A_VALID_FILTER'), 'bar')
  strictEqual(wrapper2.instance().getUrlFilter(''), 'bar')
  strictEqual(wrapper2.instance().getUrlFilter('jar=jar'), 'bar')
})

test('updateBackboneState only allows valid filters', () => {
  const wrapper = shallow(<ConversationStatusFilter {...makeProps()} />)

  wrapper.instance().updateBackboneState('foo')
  strictEqual(wrapper.state().selected, 'foo')

  wrapper.instance().updateBackboneState('bar')
  strictEqual(wrapper.state().selected, 'bar')

  wrapper.instance().updateBackboneState('NOT_A_VALID_FILTER')
  strictEqual(wrapper.state().selected, 'foo')
})
