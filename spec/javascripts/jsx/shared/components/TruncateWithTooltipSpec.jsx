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
import {mount} from 'enzyme'
import TruncateWithTooltip from '@canvas/grade-summary/react/TruncateWithTooltip'

let componentHost
let tooltipHost
let component
QUnit.module('TruncateWithTooltip', {
  beforeEach: () => {
    componentHost = document.createElement('div')
    componentHost.setAttribute('id', 'TruncateWithTooltipComponent')
    tooltipHost = document.createElement('div')
    tooltipHost.setAttribute('id', 'TruncateWithTooltipTooltip')
    document.body.appendChild(componentHost)
    document.body.appendChild(tooltipHost)
  },
  afterEach: () => {
    if (component) {
      component.unmount()
    }
    if (componentHost) {
      componentHost.remove()
    }
    if (tooltipHost) {
      tooltipHost.remove()
    }
  },
})

const render = (text, width = null) =>
  mount(
    <div style={{width}}>
      <TruncateWithTooltip mountNode={tooltipHost}>{text}</TruncateWithTooltip>
    </div>,
    {
      attachTo: componentHost,
    }
  )

test('renders the TruncateWithTooltip component', () => {
  component = render('Boo')
  ok(component.exists())
})

test('renders short text', () => {
  component = render('This is some text')
  equal(component.text(), 'This is some text')
})

test('truncates long text', () => {
  const long =
    'This is some long long long long long long long long long long long long long long text'
  component = render(long, '100px')
  notEqual(component.text(), long)
  ok(component.text().includes('\u2026'))
})

test('does not include a popover for short text', () => {
  component = render('This is some text')
  const tooltip = tooltipHost.querySelector('[role="tooltip"]')
  notOk(tooltip)
})

test('includes a popover for long text', () => {
  const long =
    'This is some long long long long long long long long long long long long long long text'
  component = render(long, '100px')
  const tooltip = tooltipHost.querySelector('[role="tooltip"]')
  ok(tooltip)
  equal(tooltip.textContent, long)
})
