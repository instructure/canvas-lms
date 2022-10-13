/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import GradebookConstants from './constants'

const I18n = useI18nScope('gradebookHelpers')

export default {
  FLASH_ERROR_CLASS: '.ic-flash-error',
  flashMaxLengthError() {
    return $.flashError(
      I18n.t('Note length cannot exceed %{maxLength} characters.', {
        maxLength: GradebookConstants.MAX_NOTE_LENGTH,
      })
    )
  },
  maxLengthErrorShouldBeShown(textareaLength) {
    return this.textareaIsGreaterThanMaxLength(textareaLength) && this.noErrorsOnPage()
  },
  noErrorsOnPage() {
    return $.find(this.FLASH_ERROR_CLASS).length === 0
  },
  textareaIsGreaterThanMaxLength(textareaLength) {
    return !this.textareaIsLessThanOrEqualToMaxLength(textareaLength)
  },
  textareaIsLessThanOrEqualToMaxLength(textareaLength) {
    return textareaLength <= GradebookConstants.MAX_NOTE_LENGTH
  },
}
