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

import api from '../ContextModuleApi'
import ModuleSequenceFooter from '@canvas/module-sequence-footer'

jest.mock('@canvas/module-sequence-footer')

describe('ContextModuleApi', () => {
  let footerInstance

  describe('getContextModuleData', () => {
    beforeEach(() => {
      footerInstance = {fetch: jest.fn(() => Promise.resolve(footerInstance))}

      ModuleSequenceFooter.mockClear()
      ModuleSequenceFooter.mockImplementation(() => footerInstance)
    })

    it('initializes a ModuleSequenceFooter object with the given course and assignment IDs', async () => {
      await api.getContextModuleData('1234', '3456')

      expect(ModuleSequenceFooter).toHaveBeenCalledWith(
        expect.objectContaining({
          assetID: '3456',
          courseID: '1234',
        })
      )
    })

    it('calls fetch() on the resulting instance', async () => {
      await api.getContextModuleData('1234', '3456')

      expect(footerInstance.fetch).toHaveBeenCalled()
    })

    it('resolves with returned data when the fetch succeeds', async () => {
      footerInstance.fetch.mockImplementation(() => {
        footerInstance.previous = {url: '/previous'}
        footerInstance.next = {url: '/next'}

        return Promise.resolve(footerInstance)
      })
      await expect(api.getContextModuleData('1', '2')).resolves.toEqual(
        expect.objectContaining({previous: {url: '/previous'}, next: {url: '/next'}})
      )
    })

    it('rejects when the fetch fails', async () => {
      footerInstance.fetch.mockRejectedValue(new Error(':('))
      await expect(api.getContextModuleData('3', '4')).rejects.toThrow(':(')
    })
  })
})
