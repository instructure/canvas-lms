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
 import Backbone from '@canvas/backbone'
 import DateShiftView from '../DateShiftView'

describe('DateShiftViewSpec', () => {
    let dateShiftView

    beforeEach(() => {
        dateShiftView = new DateShiftView({
            model: new Backbone.Model(),
            collection: new Backbone.Collection(),
        })

        dateShiftView.$oldStartDate = {
            val: jest.fn().mockReturnThis(),
            trigger: jest.fn(),
        }
        dateShiftView.$oldEndDate = {
            val: jest.fn().mockReturnThis(),
            trigger: jest.fn(),
        }
    })

    it('uses locale dates when present', () => {
        const course = {
            start_at_locale: 'Març 20, 2025 a les 0:00',
            end_at_locale: 'Maig 15, 2025 a les 0:00',
            start_at: 'Mar 20, 2025 at 12am',
            end_at: 'May 15, 2025 at 12am',
        }

        dateShiftView.updateNewDates(course)

        expect(dateShiftView.$oldStartDate.val).toHaveBeenCalledWith(course.start_at_locale)
        expect(dateShiftView.$oldStartDate.trigger).toHaveBeenCalledWith('change')

        expect(dateShiftView.$oldEndDate.val).toHaveBeenCalledWith(course.end_at_locale)
        expect(dateShiftView.$oldEndDate.trigger).toHaveBeenCalledWith('change')
    })

    it('falls back to start_at and end_at if locale fields are missing', () => {
        const course = {
            start_at: 'Març 20, 2025 a les 0:00',
            end_at: 'Maig 16, 2025 a les 0:00',
        }

        dateShiftView.updateNewDates(course)

        // start_at_locale / end_at_locale are missing, so fallback
        expect(dateShiftView.$oldStartDate.val).toHaveBeenCalledWith(course.start_at)
        expect(dateShiftView.$oldStartDate.trigger).toHaveBeenCalledWith('change')
        expect(dateShiftView.$oldEndDate.val).toHaveBeenCalledWith(course.end_at)
        expect(dateShiftView.$oldEndDate.trigger).toHaveBeenCalledWith('change')
    })
})
