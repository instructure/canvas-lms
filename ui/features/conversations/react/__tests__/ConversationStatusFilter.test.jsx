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
import ConversationStatusFilter from '../ConversationStatusFilter'
import React from 'react'
import {render} from '@testing-library/react'

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
    props,
  )

describe('ConversationStatusFilter component', () => {
  test('default initial selected option', () => {
    const ref1 = React.createRef()
    render(<ConversationStatusFilter {...makeProps()} ref={ref1} />)
    expect(ref1.current.state.selected).toStrictEqual('foo')

    const ref2 = React.createRef()
    render(<ConversationStatusFilter {...makeProps({initialFilter: 'bar'})} ref={ref2} />)
    expect(ref2.current.state.selected).toStrictEqual('bar')
  })

  test('getUrlFilter accepts valid filters', () => {
    const ref = React.createRef()
    render(<ConversationStatusFilter {...makeProps()} ref={ref} />)
    const instance = ref.current
    expect(instance.getUrlFilter('type=foo')).toStrictEqual('foo')
    expect(instance.getUrlFilter('type=bar')).toStrictEqual('bar')
    expect(instance.getUrlFilter('type=baz')).toStrictEqual('baz')
    expect(instance.getUrlFilter('jar=jar&type=foo')).toStrictEqual('foo')
    expect(instance.getUrlFilter('jar=jar&type=bar')).toStrictEqual('bar')
    expect(instance.getUrlFilter('jar=jar&type=baz')).toStrictEqual('baz')
  })

  test('getUrlFilter uses defaults when invalid', () => {
    const ref1 = React.createRef()
    render(<ConversationStatusFilter {...makeProps()} ref={ref1} />)
    const instance1 = ref1.current
    expect(instance1.getUrlFilter('type=NOT_A_VALID_FILTER')).toStrictEqual('foo')
    expect(instance1.getUrlFilter('jar=jar&type=NOT_A_VALID_FILTER')).toStrictEqual('foo')
    expect(instance1.getUrlFilter('')).toStrictEqual('foo')
    expect(instance1.getUrlFilter('jar=jar')).toStrictEqual('foo')

    const ref2 = React.createRef()
    render(<ConversationStatusFilter {...makeProps({defaultFilter: 'bar'})} ref={ref2} />)
    const instance2 = ref2.current
    expect(instance2.getUrlFilter('type=NOT_A_VALID_FILTER')).toStrictEqual('bar')
    expect(instance2.getUrlFilter('jar=jar&type=NOT_A_VALID_FILTER')).toStrictEqual('bar')
    expect(instance2.getUrlFilter('')).toStrictEqual('bar')
    expect(instance2.getUrlFilter('jar=jar')).toStrictEqual('bar')
  })

  test('updateBackboneState only allows valid filters', () => {
    const ref = React.createRef()
    render(<ConversationStatusFilter {...makeProps()} ref={ref} />)
    const instance = ref.current

    instance.updateBackboneState('foo')
    expect(instance.state.selected).toStrictEqual('foo')

    instance.updateBackboneState('bar')
    expect(instance.state.selected).toStrictEqual('bar')

    instance.updateBackboneState('NOT_A_VALID_FILTER')
    expect(instance.state.selected).toStrictEqual('foo')
  })
})
