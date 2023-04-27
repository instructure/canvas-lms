/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {
  underscoreString,
  underscoreProperties,
  camelizeString,
  camelizeProperties,
} from '../convert-case'

describe('underscoreString', () => {
  it('converts camelCase to camel_case', () => {
    expect(underscoreString('camelCase')).toEqual('camel_case')
  })

  it('converts _camelCase to camel_case', () => {
    expect(underscoreString('_camelCase')).toEqual('camel_case')
  })

  it('converts CamelCase to camel_case', () => {
    expect(underscoreString('CamelCase')).toEqual('camel_case')
  })
})

describe('underscoreProperties', () => {
  it('converts camelCase to camel_case', () => {
    expect(underscoreProperties({camelCase: true})).toEqual({camel_case: true})
  })

  it('converts _camelCase to camel_case', () => {
    expect(underscoreProperties({_camelCase: true})).toEqual({camel_case: true})
  })

  it('converts CamelCase to camel_case', () => {
    expect(underscoreProperties({CamelCase: true})).toEqual({camel_case: true})
  })
})

describe('camelizeString (PascalCase)', () => {
  it('converts camel_case to camelCase', () => {
    expect(camelizeString('camel_case')).toEqual('CamelCase')
  })

  it('converts CamelCase to camelCase', () => {
    expect(camelizeString('CamelCase')).toEqual('CamelCase')
  })
})

describe('camelizeString', () => {
  it('converts camel_case to camelCase', () => {
    expect(camelizeString('camel_case', true)).toEqual('camelCase')
  })

  it('converts CamelCase to camelCase', () => {
    expect(camelizeString('CamelCase', true)).toEqual('camelCase')
  })
})

describe('camelizeProperties', () => {
  it('converts camel_case to camelCase', () => {
    expect(camelizeProperties({camel_case: true})).toEqual({camelCase: true})
  })

  it('converts CamelCase to camelCase', () => {
    expect(camelizeProperties({CamelCase: true})).toEqual({camelCase: true})
  })
})
