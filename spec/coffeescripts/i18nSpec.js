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

// note: most of these tests are now redundant w/ i18nliner-js, leaving them
// for a little bit though

import $ from 'jquery'
import I18n from 'i18nObj'
import I18nStubber from 'helpers/I18nStubber'
import 'jquery.instructure_misc_helpers' // for $.raw

const scope = I18n.scoped('foo')
const t = (...args) => scope.t(...Array.from(args || []))
const interpolate = (...args) => I18n.interpolate(...Array.from(args || []))

QUnit.module('I18n', {
  setup() {
    return I18nStubber.pushFrame()
  },

  teardown() {
    return I18nStubber.popFrame()
  }
})

test('missing placeholders', () => {
  equal(t('k', 'ohai %{name}'), 'ohai [missing %{name} value]')
  equal(t('k', 'ohai %{name}', {name: null}), 'ohai [missing %{name} value]')
  equal(t('k', 'ohai %{name}', {name: undefined}), 'ohai [missing %{name} value]')
})

test('default locale fallback on lookup', () => {
  I18nStubber.stub('en', {foo: {fallback_message: 'this is in the en locale'}}, () => {
    I18n.locale = 'bad-locale'
    equal(scope.lookup('foo.fallback_message'), 'this is in the en locale')
  })
})

test('fallbacks should only include valid ancestors', () => {
  I18nStubber.stub(
    {en: {}, fr: {}, 'fr-CA': {}, 'fr-FR': {}, 'fr-FR-oh-la-la': {}, 'zh-Hant': {}},
    null,
    () => {
      deepEqual(I18n.getLocaleAndFallbacks('fr-FR-oh-la-la'), [
        'fr-FR-oh-la-la',
        'fr-FR',
        'fr',
        'en'
      ])
    }
  )
})

test('fallbacks should not include the default twice', () => {
  I18nStubber.stub({en: {}, 'en-GB': {}, 'en-GB-x-custom': {}}, null, () => {
    deepEqual(I18n.getLocaleAndFallbacks('en-GB-x-custom'), ['en-GB-x-custom', 'en-GB', 'en'])
  })
})

test('html safety: should not html-escape translations or interpolations by default', () => {
  equal(
    t('bar', 'these are some tags: <input> and %{another}', {another: '<img>'}),
    'these are some tags: <input> and <img>'
  )
})

test('html safety: should html-escape translations and interpolations if any interpolated values are htmlSafe', () => {
  equal(
    t('bar', "only one of these won't get escaped: <input>, %{a}, %{b} & %{c}", {
      a: '<img>',
      b: $.raw('<br>'),
      c: '<hr>'
    }),
    'only one of these won&#39;t get escaped: &lt;input&gt;, &lt;img&gt;, <br> &amp; &lt;hr&gt;'
  )
})

test('wrappers: should auto-html-escape', () => {
  equal(t('bar', '*2* > 1', {wrapper: '<b>$1</b>'}), '<b>2</b> &gt; 1')
})

test('wrappers: should not escape already-escaped text', () => {
  equal(
    t('bar', '*%{input}* > 1', {input: $.raw('<input>'), wrapper: '<b>$1</b>'}),
    '<b><input></b> &gt; 1'
  )
})

test('wrappers: should support multiple wrappers', () => {
  equal(
    t('bar', '*1 + 1* == **2**', {wrapper: {'*': '<i>$1</i>', '**': '<b>$1</b>'}}),
    '<i>1 + 1</i> == <b>2</b>'
  )
})

test('wrappers: should replace globally', () => {
  equal(t('bar', '*1 + 1* == *2*', {wrapper: '<i>$1</i>'}), '<i>1 + 1</i> == <i>2</i>')
})

test('wrappers: should interpolate placeholders in wrappers', () => {
  // this functionality is primarily useful in handlebars templates where
  // wrappers are auto-generated ... in normal js you'd probably just
  // manually concatenate it into your wrapper
  equal(
    t('bar', 'you need to *log in*', {wrapper: '<a href="%{url}">$1</a>', url: 'http://foo.bar'}),
    'you need to <a href="http://foo.bar">log in</a>'
  )
})

test('interpolate: should format numbers', () => {
  equal(interpolate('user count: %{foo}', {foo: 1500}), 'user count: 1,500')
})

test('interpolate: should not format numbery strings', () => {
  equal(interpolate('user count: %{foo}', {foo: '1500'}), 'user count: 1500')
})

test('interpolate: should not mutate the options', () => {
  const options = {foo: 1500}
  interpolate('user count: %{foo}', options)
  equal(options.foo, 1500)
})

test('pluralize: should format the number', () => {
  equal(t({one: '1 thing', other: '%{count} things'}, {count: 1500}), '1,500 things')
})

QUnit.module('I18n localize number', {
  setup() {
    this.delimiter = ' '
    this.separator = ','
    I18nStubber.pushFrame()
    I18nStubber.stub('foo', {
      number: {
        format: {
          delimiter: this.delimiter,
          separator: this.separator,
          precision: 3,
          strip_insignificant_zeros: false
        }
      }
    })
    return I18nStubber.setLocale('foo')
  },

  teardown() {
    return I18nStubber.popFrame()
  }
})

test('uses delimiter from local', function() {
  equal(I18n.localizeNumber(1000), `1${this.delimiter}000`)
})

test('uses separator from local', function() {
  equal(I18n.localizeNumber(1.2), `1${this.separator}2`)
})

test('uses precision from number if not specified', function() {
  equal(I18n.localizeNumber(1.2345), `1${this.separator}2345`)
})

test('uses precision specified', function() {
  equal(I18n.localizeNumber(1.2, {precision: 3}), `1${this.separator}200`)
  equal(I18n.localizeNumber(1.2345, {precision: 3}), `1${this.separator}235`)
})

test('formats as a percentage if set to true', function() {
  equal(I18n.localizeNumber(1.2, {percentage: true}), `1${this.separator}2%`)
})

test('allows stripping of 0s to be explicitly toggled along with precision', function() {
  equal(
    I18n.localizeNumber(1.12, {precision: 4, strip_insignificant_zeros: true}),
    `1${this.separator}12`
  )
})

test('does not have precision errors with large numbers', function() {
  equal(
    I18n.localizeNumber(50000000.12),
    `50${this.delimiter}000${this.delimiter}000${this.separator}12`
  )
})
