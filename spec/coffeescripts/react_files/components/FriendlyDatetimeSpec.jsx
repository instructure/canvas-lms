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
import TestUtils from 'react-dom/test-utils'
import $ from 'jquery'
import 'jquery-migrate'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import I18n from '@canvas/i18n'
import I18nStubber from 'helpers/I18nStubber'

QUnit.module('FriendlyDatetime', {
  setup() {
    return I18nStubber.clear()
  },
})

test('parses datetime from a string', () => {
  const fDT = React.createFactory(FriendlyDatetime)
  const rendered = TestUtils.renderIntoDocument(fDT({dateTime: '1970-01-17'}))
  equal(
    $(rendered.time).find('.visible-desktop').text(),
    'Jan 17, 1970',
    'converts to readable format'
  )
  equal($(rendered.time).find('.hidden-desktop').text(), '1/17/1970', 'converts to readable format')
  ReactDOM.unmountComponentAtNode(rendered.time.parentNode)
})

test('parses datetime from a Date', () => {
  const fDT = React.createFactory(FriendlyDatetime)
  const rendered = TestUtils.renderIntoDocument(fDT({dateTime: new Date(1431570574)}))
  equal(
    $(rendered.time).find('.visible-desktop').text(),
    'Jan 17, 1970',
    'converts to readable format'
  )
  equal($(rendered.time).find('.hidden-desktop').text(), '1/17/1970', 'converts to readable format')
  ReactDOM.unmountComponentAtNode(rendered.time.parentNode)
})

test('renders the prefix if a prefix is supplied', () => {
  const fDT = React.createFactory(FriendlyDatetime)
  const rendered = TestUtils.renderIntoDocument(
    fDT({dateTime: '1970-01-17', prefix: 'foobar ', prefixMobile: 'foobaz '})
  )
  equal(
    $(rendered.time).find('.visible-desktop').text(),
    'foobar Jan 17, 1970',
    'converts to readable format'
  )
  equal(
    $(rendered.time).find('.hidden-desktop').text(),
    'foobaz 1/17/1970',
    'converts to readable format'
  )
  ReactDOM.unmountComponentAtNode(rendered.time.parentNode)
})

test('will automatically put a space on the prefix if necessary', () => {
  const fDT = React.createFactory(FriendlyDatetime)
  const rendered = TestUtils.renderIntoDocument(
    fDT({dateTime: '1970-01-17', prefix: 'foobar', prefixMobile: 'foobaz'})
  )
  equal(
    $(rendered.time).find('.visible-desktop').text(),
    'foobar Jan 17, 1970',
    'converts to readable format'
  )
  equal(
    $(rendered.time).find('.hidden-desktop').text(),
    'foobaz 1/17/1970',
    'converts to readable format'
  )
  ReactDOM.unmountComponentAtNode(rendered.time.parentNode)
})

test('formats date with time when "showTime" is true', () => {
  const fDT = React.createFactory(FriendlyDatetime)
  const rendered = TestUtils.renderIntoDocument(fDT({dateTime: '1970-01-17', showTime: true}))
  equal(
    $(rendered.time).find('.visible-desktop').text(),
    'Jan 17, 1970 at 12am',
    'converts to readable format'
  )
  equal($(rendered.time).find('.hidden-desktop').text(), '1/17/1970', 'converts to readable format')
  ReactDOM.unmountComponentAtNode(rendered.time.parentNode)
})
