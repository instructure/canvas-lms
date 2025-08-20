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

import {prepareItemData} from '../editItemHandlers'
import {
  transformModuleItemsForTray,
  transformRequirementsForTray,
} from '../modulePageActionHandlers'

describe('editItemHandlers', () => {
  describe('prepareItemData', () => {
    it('should prepare item data', () => {
      const itemData = {
        title: 'Testing',
        indentation: 3,
        newTab: true,
      }
      const result = prepareItemData(itemData)
      expect(result).toEqual({
        'content_tag[title]': 'Testing',
        'content_tag[indent]': 3,
        'content_tag[new_tab]': 1,
        new_tab: 0,
        graded: 0,
        _method: 'PUT',
      })
    })

    it('should prepare item data for url field', () => {
      const itemData = {
        title: '',
        indentation: 0,
        url: 'https://example.com',
      }
      const result = prepareItemData(itemData)
      expect(result).toEqual({
        'content_tag[title]': '',
        'content_tag[indent]': 0,
        'content_tag[url]': 'https://example.com',
        'content_tag[new_tab]': 0,
        new_tab: 0,
        graded: 0,
        _method: 'PUT',
      })
    })

    it('handles empty title', () => {
      const inputData = {
        title: '',
        indentation: 0,
      }

      const result = prepareItemData(inputData)

      expect(result).toEqual({
        'content_tag[title]': '',
        'content_tag[indent]': 0,
        'content_tag[new_tab]': 0,
        new_tab: 0,
        graded: 0,
        _method: 'PUT',
      })
    })
  })

  describe('transformModuleItemsForTray', () => {
    it('maps new quiz engine items to resource "quiz" and stringifies points', () => {
      const raw = [
        {
          _id: '1',
          title: 'New Quiz',
          content: {isNewQuiz: true, graded: true, pointsPossible: 10},
        },
      ]

      const result = transformModuleItemsForTray(raw)

      expect(result).toEqual([
        {
          id: '1',
          name: 'New Quiz',
          resource: 'quiz',
          graded: true,
          pointsPossible: '10',
        },
      ])
    })

    it('derives resource from content.type (case-insensitive) when not a new quiz', () => {
      const raw = [
        {_id: '2', title: 'File Item', content: {type: 'File', graded: false}},
        {_id: '3', title: 'Discussion Item', content: {type: 'discussion', graded: false}},
        {_id: '4', title: 'External Url', content: {type: 'externalurl', graded: false}},
        {_id: '5', title: 'Page Item', content: {type: 'wiki_page', graded: false}},
        {_id: '6', title: 'Assignment Item', content: {type: 'assignment', graded: false}},
        {_id: '7', title: 'External Tool', content: {type: 'context_external_tool', graded: false}},
        {_id: '8', title: 'Quiz (old engine)', content: {type: 'quiz', graded: false}},
      ]

      const result = transformModuleItemsForTray(raw)

      const get = (id: string) => result.find(i => i.id === id)?.resource
      expect(get('2')).toBe('file')
      expect(get('3')).toBe('discussion')
      expect(get('4')).toBe('externalUrl')
      expect(get('5')).toBe('page')
      expect(get('6')).toBe('assignment')
      expect(get('7')).toBe('externalTool')
      expect(get('8')).toBe('quiz')
    })

    it('filters out SubHeader items', () => {
      const raw = [
        {_id: 'a', title: 'Section Header', content: {type: 'SubHeader'}},
        {_id: 'b', title: 'Real Item', content: {type: 'File'}},
      ]

      const result = transformModuleItemsForTray(raw)

      expect(result.map(i => i.id)).toEqual(['b'])
    })

    it('handles missing fields gracefully and defaults resource to "assignment"', () => {
      const raw = [
        {
          // no _id or title, no points
          content: {},
        } as any,
      ]

      const result = transformModuleItemsForTray(raw)

      expect(result).toEqual([
        {
          id: '',
          name: '',
          resource: 'assignment',
          graded: undefined,
          pointsPossible: '',
        },
      ])
    })
  })

  describe('transformRequirementsForTray', () => {
    const rawModuleItems = [
      {
        _id: 'nq1',
        title: 'Graded New Quiz',
        content: {isNewQuiz: true, graded: true, pointsPossible: 15},
      },
      {
        _id: 'oq1',
        title: 'Classic Quiz',
        content: {type: 'Quiz', graded: false, pointsPossible: 5},
      },
      {
        id: 'as1', // using `id` instead of `_id` on purpose
        title: 'Plain Assignment',
        content: {type: 'assignment', graded: true, pointsPossible: 20},
      },
      {
        _id: 'np1',
        title: 'No Points',
        content: {type: 'assignment', graded: false},
      },
    ]

    const moduleItems = [
      {id: 'nq1', name: 'Graded New Quiz', resource: 'quiz', graded: true, pointsPossible: '15'},
      {id: 'oq1', name: 'Classic Quiz', resource: 'quiz', graded: false, pointsPossible: '5'},
      {
        id: 'as1',
        name: 'Plain Assignment',
        resource: 'assignment',
        graded: true,
        pointsPossible: '20',
      },
      {id: 'np1', name: 'No Points', resource: 'assignment', graded: false, pointsPossible: ''},
    ]

    it('maps requirement types and resolves names/fields from corresponding items', () => {
      const completionRequirements = [
        {id: 'nq1', type: 'must_submit'},
        {id: 'oq1', type: 'must_view', minScore: 0},
        {id: 'as1', type: 'min_score', minScore: 12},
      ]

      const result = transformRequirementsForTray(
        completionRequirements,
        moduleItems as any[],
        rawModuleItems as any[],
      )

      expect(result).toEqual([
        {
          id: 'nq1',
          name: 'Graded New Quiz',
          type: 'submit',
          resource: 'quiz',
          graded: true,
          pointsPossible: '15',
          minimumScore: '0',
        },
        {
          id: 'oq1',
          name: 'Classic Quiz',
          type: 'view',
          resource: 'quiz',
          graded: false,
          pointsPossible: '5',
          minimumScore: '0',
        },
        {
          id: 'as1',
          name: 'Plain Assignment',
          type: 'score',
          resource: 'assignment',
          graded: true,
          pointsPossible: '20',
          minimumScore: '12',
        },
      ])
    })

    it('defaults resource to assignment and pointsPossible to 0 if not found, uses moduleItem name when available', () => {
      const completionRequirements = [{id: 'np1', type: 'must_mark_done'}]

      const result = transformRequirementsForTray(
        completionRequirements,
        moduleItems as any[],
        rawModuleItems as any[],
      )

      expect(result).toEqual([
        {
          id: 'np1',
          name: 'No Points',
          type: 'mark',
          resource: 'assignment',
          graded: false,
          pointsPossible: '0',
          minimumScore: '0',
        },
      ])
    })

    it('supports matching raw item by either _id or id', () => {
      const completionRequirements = [{id: 'as1', type: 'must_contribute'}]

      const result = transformRequirementsForTray(
        completionRequirements,
        moduleItems as any[],
        rawModuleItems as any[],
      )

      expect(result[0]).toMatchObject({
        id: 'as1',
        name: 'Plain Assignment',
        type: 'contribute',
        resource: 'assignment',
        graded: true,
        pointsPossible: '20',
        minimumScore: '0',
      })
    })

    it('passes through unknown requirement types unchanged and fills blanks safely', () => {
      const completionRequirements = [{id: 'missing', type: 'some_custom_type'}]

      const result = transformRequirementsForTray(
        completionRequirements,
        moduleItems as any[],
        rawModuleItems as any[],
      )

      expect(result).toEqual([
        {
          id: 'missing',
          name: '',
          type: 'some_custom_type',
          resource: 'assignment',
          graded: undefined,
          pointsPossible: '0',
          minimumScore: '0',
        },
      ])
    })

    it('maps min_percentage to percentage and stringifies minScore when present', () => {
      const completionRequirements = [{id: 'oq1', type: 'min_percentage', minScore: 85}]

      const result = transformRequirementsForTray(
        completionRequirements,
        moduleItems as any[],
        rawModuleItems as any[],
      )

      expect(result[0]).toMatchObject({
        id: 'oq1',
        type: 'percentage',
        minimumScore: '85',
      })
    })
  })
})
