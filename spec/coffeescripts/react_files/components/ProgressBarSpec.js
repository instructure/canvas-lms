/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import $ from 'jquery'
import ProgressBar from 'jsx/shared/ProgressBar'

QUnit.module('ProgressBar', {
  setup() {},
  teardown() {
    $('#fixtures').empty()
  }
})

test('sets width on progress bar', () => {
  const prog = ReactDOM.render(<ProgressBar progress={35} />, $('<div>').appendTo('#fixtures')[0])
  equal(prog.refs.bar.getDOMNode().style.width, '35%')
  ReactDOM.unmountComponentAtNode(prog.getDOMNode().parentNode)
})

test('shows indeterminate loader when progress is 100 but not yet complete', () => {
  const prog = ReactDOM.render(<ProgressBar progress={100} />, $('<div>').appendTo('#fixtures')[0])
  ok(prog.refs.container.getDOMNode().className.match(/almost-done/))
  ReactDOM.unmountComponentAtNode(prog.getDOMNode().parentNode)
})

test('style width value never reaches over 100%', () => {
  const prog = ReactDOM.render(<ProgressBar progress={200} />, $('<div>').appendTo('#fixtures')[0])
  equal(prog.refs.bar.getDOMNode().style.width, '100%')
  ReactDOM.unmountComponentAtNode(prog.getDOMNode().parentNode)
})
