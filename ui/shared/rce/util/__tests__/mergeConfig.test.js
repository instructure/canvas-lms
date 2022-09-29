/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import mergeConfig from '../mergeConfig'

describe('mergeConfig', () => {
  let optionsToMerge, defaultOptions, customOptions

  beforeEach(() => {
    optionsToMerge = ['foo', 'bar']
    defaultOptions = {foo: [1], bar: ['a']}
    customOptions = {foo: [2, 3], bar: ['b', 'c'], fiz: 'buz'}
  })

  const subject = () => mergeConfig(optionsToMerge, defaultOptions, customOptions)

  it('merges all options specified in "optionsToMerge"', () => {
    expect(subject()).toEqual({
      bar: ['a', 'b', 'c'],
      fiz: 'buz',
      foo: [1, 2, 3],
    })
  })

  describe('when "optionsToMerge" is empty', () => {
    beforeEach(() => {
      optionsToMerge = []
    })

    it('yields a copy of "customOptions"', () => {
      expect(subject()).toEqual(customOptions)
    })
  })

  describe('when "defaultOptions" options are not arrays', () => {
    beforeEach(() => {
      defaultOptions = {foo: 1, bar: 'a,b'}
    })

    it('does not attempt to merge options from "defaultOptions"', () => {
      expect(subject()).toEqual(customOptions)
    })
  })

  describe('when "customOptions" options are not arrays', () => {
    beforeEach(() => {
      customOptions = {foo: '2, 3', bar: 'b', fiz: 'buz'}
    })

    it('does not attempt to merge options', () => {
      expect(subject()).toEqual(customOptions)
    })
  })

  describe('when "defaultOptions" and "customOptions" arrays contain the same data', () => {
    beforeEach(() => {
      defaultOptions = {...customOptions}
    })

    it('does not include duplicates', () => {
      expect(subject()).toEqual(customOptions)
    })
  })
})
