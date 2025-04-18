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

import {prepareModuleItemData, buildFormData, createNewItemApiPath} from '../addItemHandlers'

describe('addItemHandlers', () => {
  describe('prepareModuleItemData', () => {
    it('should prepare module item data', () => {
      const itemData = {
        type: 'assignment',
        itemCount: 1,
        indentation: 0,
        textHeaderValue: 'Assignment',
        externalUrlName: 'External URL',
        externalUrlValue: 'https://example.com',
        externalUrlNewTab: false,
        selectedItem: null,
        selectedTabIndex: 0,
      }
      const result = prepareModuleItemData('moduleId', itemData)
      expect(result).toEqual({
        'item[type]': 'assignment',
        'item[position]': 2,
        'item[indent]': 0,
        quiz_lti: false,
        'content_details[]': 'items',
        type: 'assignment',
        new_tab: 0,
        graded: 0,
        _method: 'POST',
      })
    })

    it('should prepare module item data for quiz', () => {
      const itemData = {
        type: 'quiz',
        itemCount: 1,
        indentation: 0,
        textHeaderValue: 'Quiz',
        externalUrlName: 'External URL',
        externalUrlValue: 'https://example.com',
        externalUrlNewTab: false,
        selectedItem: null,
        selectedTabIndex: 0,
      }
      const result = prepareModuleItemData('moduleId', itemData)
      expect(result).toEqual({
        'item[type]': 'quiz',
        'item[position]': 2,
        'item[indent]': 0,
        quiz_lti: false,
        'content_details[]': 'items',
        type: 'quiz',
        new_tab: 0,
        graded: 0,
        _method: 'POST',
      })
    })

    it('should prepare module item data for discussion', () => {
      const itemData = {
        type: 'discussion',
        itemCount: 1,
        indentation: 0,
        textHeaderValue: 'Discussion',
        externalUrlName: 'External URL',
        externalUrlValue: 'https://example.com',
        externalUrlNewTab: false,
        selectedItem: null,
        selectedTabIndex: 0,
      }
      const result = prepareModuleItemData('moduleId', itemData)
      expect(result).toEqual({
        'item[type]': 'discussion',
        'item[position]': 2,
        'item[indent]': 0,
        quiz_lti: false,
        'content_details[]': 'items',
        type: 'discussion',
        new_tab: 0,
        graded: 0,
        _method: 'POST',
      })
    })

    it('should prepare module item data for page', () => {
      const itemData = {
        type: 'page',
        itemCount: 1,
        indentation: 0,
        textHeaderValue: 'Page',
        externalUrlName: 'External URL',
        externalUrlValue: 'https://example.com',
        externalUrlNewTab: false,
        selectedItem: null,
        selectedTabIndex: 0,
      }
      const result = prepareModuleItemData('moduleId', itemData)
      expect(result).toEqual({
        'item[type]': 'page',
        'item[position]': 2,
        'item[indent]': 0,
        quiz_lti: false,
        'content_details[]': 'items',
        type: 'page',
        new_tab: 0,
        graded: 0,
        _method: 'POST',
      })
    })

    it('should prepare module item data for text sub headers', () => {
      const itemData = {
        type: 'context_module_sub_header',
        itemCount: 1,
        indentation: 0,
        textHeaderValue: 'Text Sub Header',
        externalUrlName: 'External URL',
        externalUrlValue: 'https://example.com',
        externalUrlNewTab: false,
        selectedItem: null,
        selectedTabIndex: 0,
      }
      const result = prepareModuleItemData('moduleId', itemData)
      expect(result).toEqual({
        'item[type]': 'context_module_sub_header',
        'item[id]': 'new',
        'item[title]': 'Text Sub Header',
        title: 'Text Sub Header',
        'item[position]': 2,
        'item[indent]': 0,
        quiz_lti: false,
        'content_details[]': 'items',
        type: 'context_module_sub_header',
        new_tab: 0,
        graded: 0,
        _method: 'POST',
      })
    })

    it('should prepare module item data for external url', () => {
      const itemData = {
        type: 'external_url',
        itemCount: 1,
        indentation: 0,
        textHeaderValue: 'External URL',
        externalUrlName: 'External URL',
        externalUrlValue: 'https://example.com',
        externalUrlNewTab: false,
        selectedItem: null,
        selectedTabIndex: 0,
      }
      const result = prepareModuleItemData('moduleId', itemData)
      expect(result).toEqual({
        'item[type]': 'external_url',
        'item[id]': 'new',
        'item[title]': 'External URL',
        title: 'External URL',
        'item[position]': 2,
        'item[indent]': 0,
        'item[new_tab]': '0',
        'item[url]': 'https://example.com',
        quiz_lti: false,
        'content_details[]': 'items',
        type: 'external_url',
        new_tab: 0,
        graded: 0,
        _method: 'POST',
        url: 'https://example.com',
      })
    })
  })

  describe('buildFormData', () => {
    it('should build form data', () => {
      const type = 'assignment'
      const newItemName = 'New Assignment'
      const result = buildFormData(type, newItemName, '', false, false)
      const formData = new FormData()
      formData.append('item[id]', 'new')
      formData.append('item[title]', newItemName)
      formData.append('assignment[title]', newItemName)
      formData.append('assignment[post_to_sis]', 'false')
      expect(result).toEqual(formData)
    })

    it('should build form data for quiz', () => {
      const type = 'quiz'
      const newItemName = 'New Quiz'
      const result = buildFormData(type, newItemName, '', false, false)
      const formData = new FormData()
      formData.append('item[id]', 'new')
      formData.append('item[title]', newItemName)
      formData.append('quiz[title]', newItemName)
      formData.append('quiz[assignment_group_id]', '')
      expect(result).toEqual(formData)
    })

    it('should build form data for discussion', () => {
      const type = 'discussion'
      const newItemName = 'New Discussion'
      const result = buildFormData(type, newItemName, '', false, false)
      const formData = new FormData()
      formData.append('item[id]', 'new')
      formData.append('item[title]', newItemName)
      formData.append('title', newItemName)
      expect(result).toEqual(formData)
    })

    it('should build form data for page', () => {
      const type = 'page'
      const newItemName = 'New Page'
      const result = buildFormData(type, newItemName, '', false, false)
      const formData = new FormData()
      formData.append('item[id]', 'new')
      formData.append('item[title]', newItemName)
      formData.append('wiki_page[title]', newItemName)
      expect(result).toEqual(formData)
    })
  })

  describe('createNewItemApiPath', () => {
    it('should return correct API path', () => {
      const type = 'assignment'
      const courseId = '1'
      const result = createNewItemApiPath(type, courseId, false)
      expect(result).toEqual('/courses/1/assignments')
    })

    it('should return correct API path for quiz', () => {
      const type = 'quiz'
      const courseId = '1'
      const result = createNewItemApiPath(type, courseId, false)
      expect(result).toEqual('/courses/1/quizzes')
    })

    it('should return correct API path for discussion', () => {
      const type = 'discussion'
      const courseId = '1'
      const result = createNewItemApiPath(type, courseId, false)
      expect(result).toEqual('/api/v1/courses/1/discussion_topics')
    })

    it('should return correct API path for page', () => {
      const type = 'page'
      const courseId = '1'
      const result = createNewItemApiPath(type, courseId, false)
      expect(result).toEqual('/api/v1/courses/1/pages')
    })
  })
})
