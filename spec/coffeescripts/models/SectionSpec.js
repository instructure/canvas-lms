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

import Section from '@canvas/sections/backbone/models/Section'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('modelsSection')

QUnit.module('Section')

test("#initialize doesn't assign value for id if not given", () => {
  const section = new Section()
  strictEqual(section.id, undefined)
})

test("#Section.defaultDueDateSectionID is '0'", () =>
  strictEqual(Section.defaultDueDateSectionID, '0'))

test("Section.defaultDueDateSection returns a section with id of '0'", () => {
  const section = Section.defaultDueDateSection()
  strictEqual(section.id, '0')
  strictEqual(section.get('name'), I18n.t('overrides.everyone', 'Everyone'))
})

test("#isDefaultDueDateSection returns true if id is '0'", () =>
  strictEqual(Section.defaultDueDateSection().isDefaultDueDateSection(), true))

test("#isDefaultDueDateSection returns false if id is not '0'", () =>
  strictEqual(new Section().isDefaultDueDateSection(), false))
