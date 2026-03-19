/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
  formatFolderData,
  updateFoldersWithNewFolders,
  updateFoldersWithNewFiles,
  buildBreadcrumbPath,
} from '../folderHelpers'
import {CanvasFolder, CanvasFile} from '../../../../types'

describe('folderHelpers', () => {
  describe('formatFolderData', () => {
    it('should add empty subFolderIDs and subFileIDs to folder', () => {
      const rawFolder = {
        id: '1',
        name: 'Course Files',
        created_at: '2024-01-01',
      }

      const result = formatFolderData(rawFolder)

      expect(result).toEqual({
        id: '1',
        name: 'Course Files',
        created_at: '2024-01-01',
        subFolderIDs: [],
        subFileIDs: [],
      })
    })

    it('should preserve existing folder properties', () => {
      const rawFolder = {
        id: '2',
        name: 'Assignments',
        parent_folder_id: '1',
        full_name: 'course files/assignments',
        created_at: '2024-01-02',
        locked: true,
      }

      const result = formatFolderData(rawFolder)

      expect(result.id).toBe('2')
      expect(result.name).toBe('Assignments')
      expect(result.parent_folder_id).toBe('1')
      expect(result.full_name).toBe('course files/assignments')
      expect(result.created_at).toBe('2024-01-02')
      expect(result.locked).toBe(true)
      expect(result.subFolderIDs).toEqual([])
      expect(result.subFileIDs).toEqual([])
    })
  })

  describe('updateFoldersWithNewFolders', () => {
    it('should add new folder to empty collection', () => {
      const newFolder = {
        id: '1',
        name: 'Course Files',
        created_at: '2024-01-01',
      }

      const result = updateFoldersWithNewFolders({}, [newFolder])

      expect(result['1']).toBeDefined()
      expect(result['1'].name).toBe('Course Files')
      expect(result['1'].subFolderIDs).toEqual([])
      expect(result['1'].subFileIDs).toEqual([])
    })

    it('should add subfolder to parent subFolderIDs array', () => {
      const parentFolder: CanvasFolder = {
        id: '1',
        name: 'Course Files',
        subFolderIDs: [],
        subFileIDs: [],
      }

      const childFolder = {
        id: '2',
        name: 'Assignments',
        parent_folder_id: '1',
      }

      const result = updateFoldersWithNewFolders({'1': parentFolder}, [childFolder])

      expect(result['1'].subFolderIDs).toContain('2')
      expect(result['2']).toBeDefined()
      expect(result['2'].name).toBe('Assignments')
    })

    it('should default parent_folder_id to 0 if missing', () => {
      const folderWithoutParent = {
        id: '1',
        name: 'Root Folder',
      }

      const result = updateFoldersWithNewFolders({}, [folderWithoutParent])

      expect(result['1'].parent_folder_id).toBe('0')
      expect(result['0']).toBeDefined()
      expect(result['0'].subFolderIDs).toContain('1')
    })

    it('should not duplicate folder IDs in parent subFolderIDs', () => {
      const parentFolder: CanvasFolder = {
        id: '1',
        name: 'Course Files',
        subFolderIDs: [],
        subFileIDs: [],
      }

      const childFolder = {
        id: '2',
        name: 'Assignments',
        parent_folder_id: '1',
      }

      let result = updateFoldersWithNewFolders({'1': parentFolder}, [childFolder])
      result = updateFoldersWithNewFolders(result, [childFolder])

      expect(result['1'].subFolderIDs.filter(id => id === '2')).toHaveLength(1)
    })

    it('should preserve existing subFolderIDs when updating folder', () => {
      const existingFolder: CanvasFolder = {
        id: '1',
        name: 'Course Files',
        subFolderIDs: ['2', '3'],
        subFileIDs: [],
      }

      const updatedFolderData = {
        id: '1',
        name: 'Course Files (Updated)',
        parent_folder_id: '0',
      }

      const result = updateFoldersWithNewFolders({'1': existingFolder}, [updatedFolderData])

      expect(result['1'].subFolderIDs).toEqual(['2', '3'])
      expect(result['1'].name).toBe('Course Files (Updated)')
    })
  })

  describe('updateFoldersWithNewFiles', () => {
    it('should add file ID to parent folder subFileIDs', () => {
      const parentFolder: CanvasFolder = {
        id: '1',
        name: 'Course Files',
        subFolderIDs: [],
        subFileIDs: [],
      }

      const file: CanvasFile = {
        id: 'file-1',
        display_name: 'syllabus.pdf',
        filename: 'syllabus.pdf',
        folder_id: '1',
        created_at: '2024-01-01',
        locked: false,
      }

      const result = updateFoldersWithNewFiles({'1': parentFolder}, [file])

      expect(result['1'].subFileIDs).toContain('file-1')
    })

    it('should default to parent ID 0 if folder_id missing', () => {
      const file: CanvasFile = {
        id: 'file-1',
        display_name: 'orphan.pdf',
        filename: 'orphan.pdf',
        folder_id: '' as any,
        created_at: '2024-01-01',
        locked: false,
      }

      const result = updateFoldersWithNewFiles({}, [file])

      expect(result['0']).toBeDefined()
      expect(result['0'].subFileIDs).toContain('file-1')
    })

    it('should not duplicate file IDs in subFileIDs', () => {
      const parentFolder: CanvasFolder = {
        id: '1',
        name: 'Course Files',
        subFolderIDs: [],
        subFileIDs: [],
      }

      const file: CanvasFile = {
        id: 'file-1',
        display_name: 'syllabus.pdf',
        filename: 'syllabus.pdf',
        folder_id: '1',
        created_at: '2024-01-01',
        locked: false,
      }

      let result = updateFoldersWithNewFiles({'1': parentFolder}, [file])
      result = updateFoldersWithNewFiles(result, [file])

      expect(result['1'].subFileIDs.filter(id => id === 'file-1')).toHaveLength(1)
    })

    it('should handle multiple files in same folder', () => {
      const parentFolder: CanvasFolder = {
        id: '1',
        name: 'Course Files',
        subFolderIDs: [],
        subFileIDs: [],
      }

      const files: CanvasFile[] = [
        {
          id: 'file-1',
          display_name: 'syllabus.pdf',
          filename: 'syllabus.pdf',
          folder_id: '1',
          created_at: '2024-01-01',
          locked: false,
        },
        {
          id: 'file-2',
          display_name: 'schedule.pdf',
          filename: 'schedule.pdf',
          folder_id: '1',
          created_at: '2024-01-02',
          locked: false,
        },
        {
          id: 'file-3',
          display_name: 'notes.pdf',
          filename: 'notes.pdf',
          folder_id: '1',
          created_at: '2024-01-03',
          locked: false,
        },
      ]

      const result = updateFoldersWithNewFiles({'1': parentFolder}, files)

      expect(result['1'].subFileIDs).toHaveLength(3)
      expect(result['1'].subFileIDs).toContain('file-1')
      expect(result['1'].subFileIDs).toContain('file-2')
      expect(result['1'].subFileIDs).toContain('file-3')
    })
  })

  describe('buildBreadcrumbPath', () => {
    it('should build path for single root folder', () => {
      const folders: Record<string, CanvasFolder> = {
        '1': {
          id: '1',
          name: 'Course Files',
          subFolderIDs: [],
          subFileIDs: [],
        },
      }

      const result = buildBreadcrumbPath('1', folders)

      expect(result).toEqual([{id: '1', name: 'Course Files'}])
    })

    it('should build path from nested folder to root', () => {
      const folders: Record<string, CanvasFolder> = {
        '1': {
          id: '1',
          name: 'Course Files',
          subFolderIDs: ['2'],
          subFileIDs: [],
        },
        '2': {
          id: '2',
          name: 'Assignments',
          parent_folder_id: '1',
          subFolderIDs: ['3'],
          subFileIDs: [],
        },
        '3': {
          id: '3',
          name: 'Homework',
          parent_folder_id: '2',
          subFolderIDs: [],
          subFileIDs: [],
        },
      }

      const result = buildBreadcrumbPath('3', folders)

      expect(result).toEqual([
        {id: '1', name: 'Course Files'},
        {id: '2', name: 'Assignments'},
        {id: '3', name: 'Homework'},
      ])
    })

    it('should return path in correct order (root first)', () => {
      const folders: Record<string, CanvasFolder> = {
        '1': {
          id: '1',
          name: 'Root',
          subFolderIDs: ['2'],
          subFileIDs: [],
        },
        '2': {
          id: '2',
          name: 'Level 1',
          parent_folder_id: '1',
          subFolderIDs: ['3'],
          subFileIDs: [],
        },
        '3': {
          id: '3',
          name: 'Level 2',
          parent_folder_id: '2',
          subFolderIDs: ['4'],
          subFileIDs: [],
        },
        '4': {
          id: '4',
          name: 'Level 3',
          parent_folder_id: '3',
          subFolderIDs: [],
          subFileIDs: [],
        },
      }

      const result = buildBreadcrumbPath('4', folders)

      expect(result[0].name).toBe('Root')
      expect(result[result.length - 1].name).toBe('Level 3')
      expect(result).toHaveLength(4)
    })

    it('should handle folder with undefined parent', () => {
      const folders: Record<string, CanvasFolder> = {
        '1': {
          id: '1',
          name: 'Root',
          subFolderIDs: [],
          subFileIDs: [],
        },
        '2': {
          id: '2',
          name: 'Orphan',
          parent_folder_id: '999',
          subFolderIDs: [],
          subFileIDs: [],
        },
      }

      const result = buildBreadcrumbPath('2', folders)

      expect(result).toEqual([{id: '2', name: 'Orphan'}])
    })
  })
})
