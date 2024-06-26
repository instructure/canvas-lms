/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import I18n, {useScope} from '..'
import I18nStubber from '@canvas/test-utils/I18nStubber'
import {raw} from '@instructure/html-escape'

const scope = useScope('foo')
const t = (...args) => scope.t(...Array.from(args || []))
const interpolate = (...args) => I18n.interpolate(...Array.from(args || []))

beforeEach(() => {
  return I18nStubber.pushFrame()
})

afterEach(() => {
  return I18nStubber.clear()
})

describe('I18n', () => {
  test('missing placeholders', () => {
    expect(t('k', 'ohai %{name}')).toEqual('ohai [missing %{name} value]')
    expect(t('k', 'ohai %{name}', {name: null})).toEqual('ohai [missing %{name} value]')
    expect(t('k', 'ohai %{name}', {name: undefined})).toEqual('ohai [missing %{name} value]')
  })

  test('html safety: should not html-escape translations or interpolations by default', () => {
    expect(t('bar', 'these are some tags: <input> and %{another}', {another: '<img>'})).toEqual(
      'these are some tags: <input> and <img>'
    )
  })

  test('html safety: should html-escape translations and interpolations if any interpolated values are htmlSafe', () => {
    const result = t('bar', "only one of these won't get escaped: <input>, %{a}, %{b} & %{c}", {
      a: '<img>',
      b: raw('<br>'),
      c: '<hr>',
    })

    expect(result.string).toEqual(
      'only one of these won&#39;t get escaped: &lt;input&gt;, &lt;img&gt;, <br> &amp; &lt;hr&gt;'
    )
  })

  test('wrappers: should auto-html-escape', () => {
    const result = t('bar', '*2* > 1', {wrapper: '<b>$1</b>'})
    expect(result.string).toEqual('<b>2</b> &gt; 1')
  })

  test('wrappers: should not escape already-escaped text', () => {
    const result = t('bar', '*%{input}* > 1', {input: raw('<input>'), wrapper: '<b>$1</b>'})
    expect(result.string).toEqual('<b><input></b> &gt; 1')
  })

  test('wrappers: should support multiple wrappers', () => {
    const result = t('bar', '*1 + 1* == **2**', {wrapper: {'*': '<i>$1</i>', '**': '<b>$1</b>'}})
    expect(result.string).toEqual('<i>1 + 1</i> == <b>2</b>')
  })

  test('wrappers: should replace globally', () => {
    const result = t('bar', '*1 + 1* == *2*', {wrapper: '<i>$1</i>'})
    expect(result.string).toEqual('<i>1 + 1</i> == <i>2</i>')
  })

  test('wrappers: should interpolate placeholders in wrappers', () => {
    const result = t('bar', 'you need to *log in*', {
      wrapper: '<a href="%{url}">$1</a>',
      url: 'http://foo.bar',
    })
    expect(result.string).toEqual('you need to <a href="http://foo.bar">log in</a>')
  })

  test('interpolate: should format numbers', () => {
    expect(interpolate('user count: %{foo}', {foo: 1500})).toEqual('user count: 1,500')
  })

  test('interpolate: should not format numbery strings', () => {
    expect(interpolate('user count: %{foo}', {foo: '1500'})).toEqual('user count: 1500')
  })

  test('interpolate: should not mutate the options', () => {
    const options = {foo: 1500}
    interpolate('user count: %{foo}', options)
    expect(options.foo).toEqual(1500)
  })

  test('pluralize: should format the number', () => {
    expect(t({one: '1 thing', other: '%{count} things'}, {count: 1500})).toEqual('1,500 things')
  })
})

describe('I18n localize number', () => {
  let delimiter, separator

  beforeEach(() => {
    delimiter = ' '
    separator = ','
    I18nStubber.pushFrame()
    I18nStubber.stub('foo', {
      'number.format.delimiter': delimiter,
      'number.format.precision': 3,
      'number.format.separator': separator,
      'number.format.strip_insignificant_zeros': false,
    })
    return I18nStubber.setLocale('foo')
  })

  afterEach(() => {
    return I18nStubber.clear()
  })

  test('uses delimiter from local', () => {
    expect(I18n.localizeNumber(1000)).toEqual(`1${delimiter}000`)
  })

  test('uses separator from local', () => {
    expect(I18n.localizeNumber(1.2)).toEqual(`1${separator}2`)
  })

  test('uses precision from number if not specified', () => {
    expect(I18n.localizeNumber(1.2345)).toEqual(`1${separator}2345`)
  })

  test('uses precision specified', () => {
    expect(I18n.localizeNumber(1.2, {precision: 3})).toEqual(`1${separator}200`)
    expect(I18n.localizeNumber(1.2345, {precision: 3})).toEqual(`1${separator}235`)
  })

  test('formats as a percentage if set to true', () => {
    expect(I18n.localizeNumber(1.2, {percentage: true})).toEqual(`1${separator}2%`)
  })

  test('allows stripping of 0s to be explicitly toggled along with precision', () => {
    expect(I18n.localizeNumber(1.12, {precision: 4, strip_insignificant_zeros: true})).toEqual(
      `1${separator}12`
    )
  })

  test('does not have precision errors with large numbers', () => {
    expect(I18n.localizeNumber(50000000.12)).toEqual(
      `50${delimiter}000${delimiter}000${separator}12`
    )
  })
})
