/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import commonEventFactory from '../index'

describe('isCompleted()', () => {
  let data, contexts
  const subject = () => commonEventFactory(data, contexts)

  describe('when the event type is a todo item', () => {
    beforeEach(() => {
      data = {
        context_code: 'course_1',
        plannable_type: 'wiki_page',
        plannable: {url: 'some_title', title: 'some title', todo_date: '2016-12-01T12:30:00Z'},
      }

      contexts = [
        {asset_string: 'course_1', can_update_wiki_page: false, can_update_todo_date: false},
      ]
    })

    describe('and the item is marked complete', () => {
      beforeEach(() => {
        data.planner_override = {
          marked_complete: true,
        }
      })

      it('returns true', () => {
        expect(subject().isCompleted()).toEqual(true)
      })
    })

    describe('and the item is not marked complete', () => {
      beforeEach(() => {
        data.planner_override = {
          marked_complete: false,
        }
      })

      it('returns false', () => {
        expect(subject().isCompleted()).toEqual(false)
      })
    })
  })
})
