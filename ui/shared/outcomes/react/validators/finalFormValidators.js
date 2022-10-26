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

const I18n = useI18nScope('Validators')

export const requiredValidator = value => (!value ? I18n.t('This field is required') : null)

export const maxLengthValidator = length => value =>
  value && value.length > length ? I18n.t('Must be %{length} characters or less', {length}) : null

export const composeValidators =
  (...validators) =>
  value =>
    validators.reduce((error, validator) => error || validator(value), undefined)
