/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Section from '../Section'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('modelsSection')

describe('Section', () => {
  test("initialize doesn't assign value for id if not given", () => {
    const section = new Section()
    expect(section.id).toBeUndefined()
  })

  test("Section.defaultDueDateSectionID is '0'", () => {
    expect(Section.defaultDueDateSectionID).toBe('0')
  })

  test("Section.defaultDueDateSection returns a section with id of '0'", () => {
    const section = Section.defaultDueDateSection()
    expect(section.id).toBe('0')
    expect(section.get('name')).toBe(I18n.t('overrides.everyone', 'Everyone'))
  })

  test("isDefaultDueDateSection returns true if id is '0'", () => {
    expect(Section.defaultDueDateSection().isDefaultDueDateSection()).toBe(true)
  })

  test("isDefaultDueDateSection returns false if id is not '0'", () => {
    expect(new Section().isDefaultDueDateSection()).toBe(false)
  })
})
