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
  getDayBoundaries,
  getFromLocalStorage,
  removeStringAffix,
  safeDateConversion,
  setToLocalStorage,
  splitArrayByProperty,
} from '../../util/helpers'

interface CircularReference {
  ref?: CircularReference
}

describe('helpers.ts', () => {
  describe('local storage', () => {
    beforeEach(() => {
      localStorage.clear()
      jest.clearAllMocks()
    })

    describe('getFromLocalStorage', () => {
      it('returns undefined if the key does not exist', () => {
        const retrievedData = getFromLocalStorage('nonExistentKey')
        expect(retrievedData).toBeUndefined()
      })

      it('logs an error when retrieving unparsable data', () => {
        localStorage.setItem('invalidJSON', 'This is not valid JSON.')
        const errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
        getFromLocalStorage('invalidJSON')
        expect(errorSpy).toHaveBeenCalled()
        errorSpy.mockRestore()
      })

      it('returns undefined when the stored value is null', () => {
        localStorage.setItem('nullKey', 'null')

        const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {})

        const retrievedData = getFromLocalStorage('nullKey')
        expect(retrievedData).toBeUndefined()

        warnSpy.mockRestore()
      })

      it('returns undefined for non-object values', () => {
        localStorage.setItem('stringKey', '"stringValue"')

        const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {})

        const retrievedData = getFromLocalStorage('stringKey')
        expect(retrievedData).toBeUndefined()

        warnSpy.mockRestore()
      })

      it('correctly retrieves an item', () => {
        const sampleData = {key: 'value'}
        localStorage.setItem('sampleKey', JSON.stringify(sampleData))
        const retrievedData = getFromLocalStorage('sampleKey')
        expect(retrievedData).toEqual(sampleData)
      })
    })

    describe('setToLocalStorage', () => {
      it('correctly sets an item', () => {
        const sampleData = {key: 'value'}
        setToLocalStorage('sampleKey', sampleData)

        const storedData = localStorage.getItem('sampleKey')
        expect(storedData).not.toBeNull()
        expect(JSON.parse(storedData!)).toEqual(sampleData)
      })

      it('does not modify localStorage when there is a serialization error', () => {
        const circularRef: any = {}
        const initialLocalStorage = {...localStorage}
        const errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

        circularRef.ref = circularRef
        setToLocalStorage('circularKey', circularRef)

        expect(errorSpy).toHaveBeenCalled()
        expect(localStorage).toEqual(initialLocalStorage)

        errorSpy.mockRestore()
      })

      it('handles exceptions when trying to set invalid data', () => {
        const circularRef: CircularReference = {}
        circularRef.ref = circularRef

        const errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
        setToLocalStorage('circularKey', circularRef)
        expect(errorSpy).toHaveBeenCalled()
        errorSpy.mockRestore()
      })
    })
  })

  describe('date/time', () => {
    describe('getDayBoundaries', () => {
      it('returns start and end of the day', () => {
        const date = new Date(2023, 8, 13, 15, 30) // Sep 13, 2023, 15:30
        const [start, end] = getDayBoundaries(date)

        expect(start).toEqual(new Date(2023, 8, 13, 0, 1, 0, 0))
        expect(end).toEqual(new Date(2023, 8, 13, 23, 59, 59, 999))
      })
    })
  })

  describe('string', () => {
    describe('removeStringAffix', () => {
      it('correctly removes the specified suffix', () => {
        const result = removeStringAffix('HelloWorld', 'World')

        expect(result).toEqual('Hello')
      })

      it('correctly removes the specified prefix', () => {
        const result = removeStringAffix('HelloWorld', 'Hello', 'prefix')

        expect(result).toEqual('World')
      })

      it('returns the original string if the suffix does not match', () => {
        const result = removeStringAffix('HelloWorld', 'Hello')

        expect(result).toEqual('HelloWorld')
      })

      it('returns the original string if the prefix does not match', () => {
        const result = removeStringAffix('HelloWorld', 'World', 'prefix')

        expect(result).toEqual('HelloWorld')
      })

      it('returns an empty string if the main string is empty', () => {
        const result = removeStringAffix('', 'Hello')

        expect(result).toEqual('')
      })

      it('returns the original string if the affix is empty', () => {
        const result = removeStringAffix('HelloWorld', '')

        expect(result).toEqual('HelloWorld')
      })
    })
  })

  describe('date conversion', () => {
    describe('safeDateConversion', () => {
      it('correctly converts a valid date string to a Date object', () => {
        const result = safeDateConversion('2023-09-13T15:30:00Z')

        expect(result).toBeInstanceOf(Date)
        expect(result!.toISOString()).toEqual('2023-09-13T15:30:00.000Z')
      })

      it('returns the same Date object if input is already a Date object', () => {
        const inputDate = new Date('2023-09-13T15:30:00Z')
        const result = safeDateConversion(inputDate)

        expect(result).toBeInstanceOf(Date)
        expect(result).toEqual(inputDate)
      })

      it('returns undefined for an invalid date string', () => {
        const result = safeDateConversion('invalid-date')

        expect(result).toBeUndefined()
      })

      it('returns undefined for an empty string', () => {
        const result = safeDateConversion('')

        expect(result).toBeUndefined()
      })

      it('returns undefined if the input is undefined', () => {
        const result = safeDateConversion(undefined)

        expect(result).toBeUndefined()
      })

      it('returns undefined for a non-date string', () => {
        const result = safeDateConversion('Hello World')

        expect(result).toBeUndefined()
      })
    })
  })

  describe('array', () => {
    describe('splitArrayByProperty', () => {
      it('splits an array based on the specified string property', () => {
        const input = [
          {category: 'fruit', name: 'apple'},
          {category: 'vegetable', name: 'carrot'},
          {category: 'fruit', name: 'banana'},
        ]
        const result = splitArrayByProperty(input, 'category')

        expect(result).toEqual({
          fruit: [
            {category: 'fruit', name: 'apple'},
            {category: 'fruit', name: 'banana'},
          ],
          vegetable: [{category: 'vegetable', name: 'carrot'}],
        })
      })

      it('returns an empty object when the input array is empty', () => {
        const result = splitArrayByProperty([], 'category')

        expect(result).toEqual({})
      })

      it('returns all items under "undefined" key if property is missing', () => {
        const input = [{name: 'apple'}, {name: 'banana'}]
        const result = splitArrayByProperty(input, 'category')

        expect(result).toEqual({
          undefined: [{name: 'apple'}, {name: 'banana'}],
        })
      })
    })
  })
})
