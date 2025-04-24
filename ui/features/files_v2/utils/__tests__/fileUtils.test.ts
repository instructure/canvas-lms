/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {datetimeString} from '@canvas/datetime/date-functions'
import {
  isPublished,
  isRestricted,
  isHidden,
  getRestrictedText,
  generatePreviewUrlPath,
  externalToolEnabled,
} from '../fileUtils'
import {type File} from '../../interfaces/File'

describe('fileUtils', () => {
  describe('isPublished', () => {
    it('should return true if the item is not locked', () => {
      const item: File = {locked: false} as File
      expect(isPublished(item)).toBe(true)
    })

    it('should return false if the item is locked', () => {
      const item: File = {locked: true} as File
      expect(isPublished(item)).toBe(false)
    })
  })

  describe('isRestricted', () => {
    it('should return true if the item has lock_at or unlock_at', () => {
      const item: File = {lock_at: new Date().toDateString(), unlock_at: null} as File
      expect(isRestricted(item)).toBe(true)
    })

    it('should return false if the item has neither lock_at nor unlock_at', () => {
      const item: File = {lock_at: null, unlock_at: null} as File
      expect(isRestricted(item)).toBe(false)
    })
  })

  describe('isHidden', () => {
    it('should return true if the item is hidden', () => {
      const item: File = {hidden: true} as File
      expect(isHidden(item)).toBe(true)
    })

    it('should return false if the item is not hidden', () => {
      const item: File = {hidden: false} as File
      expect(isHidden(item)).toBe(false)
    })
  })

  describe('getRestrictedText', () => {
    it('should return correct text for both unlock_at and lock_at', () => {
      const unlockAt = new Date().toDateString()
      const lockAt = new Date().toDateString()
      const item: File = {
        unlock_at: unlockAt,
        lock_at: lockAt,
      } as File
      expect(getRestrictedText(item)).toBe(
        `Available from ${datetimeString(unlockAt)} until ${datetimeString(lockAt)}`,
      )
    })

    it('should return correct text for only unlock_at', () => {
      const unlockAt = new Date().toDateString()
      const item: File = {unlock_at: unlockAt, lock_at: null} as File
      expect(getRestrictedText(item)).toBe(`Available from ${datetimeString(unlockAt)}`)
    })

    it('should return correct text for only lock_at', () => {
      const lockAt = new Date().toDateString()
      const item: File = {unlock_at: null, lock_at: lockAt} as File
      expect(getRestrictedText(item)).toBe(`Available until ${datetimeString(lockAt)}`)
    })
  })

  describe('generatePreviewUrlPath', () => {
    it('should return the correct preview URL path', () => {
      const item: File = {context_asset_string: 'model_1', id: 123} as File
      expect(generatePreviewUrlPath(item)).toBe('?preview=123')
    })

    it('should throw an error if context_asset_string is missing', () => {
      const item: File = {context_asset_string: '', id: 123} as File
      expect(() => generatePreviewUrlPath(item)).toThrow(
        'File must have context_asset_string and id properties',
      )
    })

    it('should throw an error if context_asset_string format is invalid', () => {
      const item: File = {context_asset_string: 'invalid', id: 123} as File
      expect(() => generatePreviewUrlPath(item)).toThrow('Invalid context_asset_string format')
    })
  })

  describe('externalToolEnabled', () => {
    it('should return true if the tool accepts media type', () => {
      const file = {'content-type': 'image/png'} as File
      const tool = {accept_media_types: 'image/*'} as any
      expect(externalToolEnabled(file, tool)).toBe(true)
    })

    it('should return false if the tool does not accept media type', () => {
      const file = {'content-type': 'image/png'} as File
      const tool = {accept_media_types: 'video/*'} as any
      expect(externalToolEnabled(file, tool)).toBe(false)
    })

    it('should return true if the tool does not accept any media type', () => {
      const file = {'content-type': 'image/png'} as File
      const tool = {accept_media_types: ''} as any
      expect(externalToolEnabled(file, tool)).toBe(true)
    })

    it('should return false if file has empty content-type', () => {
      const file = {'content-type': ''} as File
      const tool = {accept_media_types: 'image/*'} as any
      expect(externalToolEnabled(file, tool)).toBe(false)
    })

    it('should return false if file has no content-type', () => {
      const file = {} as File
      const tool = {accept_media_types: 'image/*'} as any
      expect(externalToolEnabled(file, tool)).toBe(false)
    })
  })
})
