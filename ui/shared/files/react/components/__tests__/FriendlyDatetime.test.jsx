/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import I18nStubber from '@canvas/test-utils/I18nStubber'

// Clear I18nStubber before each test
beforeEach(() => {
  I18nStubber.clear()
})

test('parses datetime from a string', () => {
  const {container} = render(<FriendlyDatetime dateTime="1970-01-17" />)
  expect(container.querySelector('.visible-desktop').textContent).toBe('Jan 17, 1970')
  expect(container.querySelector('.hidden-desktop').textContent).toBe('1/17/1970')
})

test('parses datetime from a Date', () => {
  const {container} = render(<FriendlyDatetime dateTime={new Date(1431570574)} />)
  expect(container.querySelector('.visible-desktop').textContent).toBe('Jan 17, 1970')
  expect(container.querySelector('.hidden-desktop').textContent).toBe('1/17/1970')
})

test('renders the prefix if a prefix is supplied', () => {
  const {container} = render(
    <FriendlyDatetime dateTime="1970-01-17" prefix="foobar " prefixMobile="foobaz " />
  )
  expect(container.querySelector('.visible-desktop').textContent).toBe('foobar Jan 17, 1970')
  expect(container.querySelector('.hidden-desktop').textContent).toBe('foobaz 1/17/1970')
})

test('will automatically put a space on the prefix if necessary', () => {
  const {container} = render(
    <FriendlyDatetime dateTime="1970-01-17" prefix="foobar" prefixMobile="foobaz" />
  )
  expect(container.querySelector('.visible-desktop').textContent).toBe('foobar Jan 17, 1970')
  expect(container.querySelector('.hidden-desktop').textContent).toBe('foobaz 1/17/1970')
})

test('formats date with time when "showTime" is true', () => {
  const {container} = render(<FriendlyDatetime dateTime="1970-01-17" showTime={true} />)
  expect(container.querySelector('.visible-desktop').textContent).toBe('Jan 17, 1970 at 12am')
  expect(container.querySelector('.hidden-desktop').textContent).toBe('1/17/1970')
})
