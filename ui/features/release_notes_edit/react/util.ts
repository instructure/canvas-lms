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

import {useScope as createI18nScope} from '@canvas/i18n'
import {type ReleaseNote, ReleaseNoteEditing} from './types'

const I18n = createI18nScope('release_notes')

export const roles = [
  {
    id: 'user',
    label: I18n.t('Everyone'),
  },
  {
    id: 'admin',
    label: I18n.t('Admins'),
  },
  {
    id: 'teacher',
    label: I18n.t('Teachers'),
  },
  {
    id: 'student',
    label: I18n.t('Students'),
  },
  {
    id: 'observer',
    label: I18n.t('Observers'),
  },
]

export const rolesObject = Object.fromEntries(roles.map(r => [r.id, r.label]))

const DEFAULT_STATE: ReleaseNoteEditing = {
  target_roles: ['user'],
  langs: {en: {title: '', description: ''}},
  show_ats: {},
  published: false,
  elementsWithErrors: {},
  isSubmitting: false,
}

export function createDefaultState(current: ReleaseNote | null): ReleaseNoteEditing {
  if (current) return {...DEFAULT_STATE, ...current}
  return DEFAULT_STATE
}
