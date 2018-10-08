/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import numberFormat from 'jsx/shared/helpers/numberFormat'

import I18n from 'i18nObj'

QUnit.module('numberFormat _format', {
  teardown() {
    if (I18n.n.restore) {
      I18n.n.restore()
    }
  }
})

test('passes through non-numbers', () => {
  equal(numberFormat._format('foo'), 'foo')
  ok(isNaN(numberFormat._format(NaN)))
})

test('proxies to I18n for numbers', () => {
  sinon.stub(I18n, 'n').returns('1,23')
  equal(numberFormat._format(1.23, {foo: 'bar'}), '1,23')
  ok(I18n.n.calledWithMatch(1.23, {foo: 'bar'}))
})

QUnit.module('numberFormat outcomeScore')

test('requests precision 2', () => {
  equal(numberFormat.outcomeScore(1.234), '1.23')
})

test('requests strip insignificant zeros', () => {
  equal(numberFormat.outcomeScore(1.00001), '1')
})
