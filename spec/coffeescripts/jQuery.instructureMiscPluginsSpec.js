/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import jQuery from 'jquery'
import 'jquery.instructure_misc_plugins'

const $ = jQuery

QUnit.module('instructure misc plugins')

test('showIf', function() {
  const el = $('<input type="checkbox" id="checkbox1">').appendTo('#fixtures')
  el.showIf(() => true)
  equal(el.is(':visible'), true, 'should show if callback returns true')
  el.showIf(() => false)
  equal(el.is(':visible'), false, 'should be hidden if callback returns false')
  el.showIf(true)
  equal(el.is(':visible'), true, 'should show if true as argument')
  el.showIf(false)
  equal(el.is(':visible'), false, 'should not show if false as argument')
  el.showIf(true)
  equal(el.is(':visible'), true)
  ok(el.showIf(() => true) === el)
  ok(el.showIf(() => false) === el)
  ok(el.showIf(true) === el)
  ok(el.showIf(false) === el)
  el.showIf(function() {
    ok(this.nodeType)
    notEqual(this.constructor, jQuery)
  })
  return el.remove()
})

test('disableIf', () => {
  const el = $('<input type="checkbox" id="checkbox1">').appendTo($('#fixtures'))
  el.disableIf(() => true)
  equal(el.is(':disabled'), true)
  el.disableIf(() => false)
  equal(el.is(':disabled'), false)
  el.disableIf(() => true)
  equal(el.is(':disabled'), true)
  el.disableIf(false)
  equal(el.is(':disabled'), false)
  el.disableIf(true)
  equal(el.is(':disabled'), true)
  equal(el.disableIf(() => true), el)
  equal(el.disableIf(() => false), el)
  equal(el.disableIf(true), el)
  equal(el.disableIf(false), el)
  return el.remove()
})
