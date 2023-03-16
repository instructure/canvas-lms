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
import {useScope as useI18nScope} from '@canvas/i18n'
import StudentColumnHeader from './StudentColumnHeader'

const I18n = useI18nScope('gradebook')

export default class StudentFirstNameColumnHeader extends StudentColumnHeader {
  getColumnHeaderName(): string {
    return I18n.t('Student First Name')
  }

  getColumnHeaderOptions(): string {
    return I18n.t('Student First Name Options')
  }

  showDisplayAsViewOption(): boolean {
    return false
  }

  getHeaderTestId(): string {
    return 'first-name-header'
  }
}
