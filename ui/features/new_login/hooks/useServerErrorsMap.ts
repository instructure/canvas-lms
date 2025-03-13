/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

const I18n = createI18nScope('new_login')

export const useServerErrorsMap = (): {[key: string]: () => string} => {
  return {
    // taken from ui/shared/users/backbone/models/User.js
    'user.name.blank': () => I18n.t('Please enter your name.'),
    'user.name.too_long': () => I18n.t('Name must be %{max} characters or fewer.', {max: 255}),
    'user.self_enrollment_code.blank': () => I18n.t('Please enter an enrollment code.'),
    'user.self_enrollment_code.invalid': () => I18n.t('The enrollment code is invalid.'),
    'user.self_enrollment_code.already_enrolled': () =>
      I18n.t('You are already enrolled in this course.'),
    'user.self_enrollment_code.concluded': () => I18n.t('This course has ended.'),
    'user.self_enrollment_code.full': () => I18n.t('This course is full.'),
    'user.terms_of_use.accepted': () => I18n.t('You must accept the terms to proceed.'),
    'pseudonym.unique_id.too_short': () => I18n.t('Please enter your username.'),
    'pseudonym.unique_id.too_long': () =>
      I18n.t('Username must be %{max} characters or fewer.', {max: 100}),
    'pseudonym.unique_id.invalid': () =>
      I18n.t('Username can only include letters, numbers, or the following: %{characters}', {
        characters: '. + - _ @ =',
      }),
    'pseudonym.unique_id.taken': () => I18n.t('This username is already in use.'),
    'pseudonym.unique_id.bad_credentials': () => I18n.t('Invalid username or password.'),
    'pseudonym.unique_id.not_email': () => I18n.t('Please enter a valid email address.'),
    'pseudonym.sis_user_id.too_long': () =>
      I18n.t('SIS ID must be %{max} characters or fewer.', {max: 255}),
    'pseudonym.sis_user_id.taken': () => I18n.t('This SIS ID is already in use.'),

    // taken from ui/shared/pseudonyms/backbone/models/Pseudonym.js
    'pseudonym.password.too_short': () => I18n.t('Password does not meet the length requirement.'),
    'pseudonym.password.too_long': () => I18n.t('Password exceeds the allowed length.'),
    'pseudonym.password.repeated': () => I18n.t('Password contains too many repeated characters.'),
    'pseudonym.password.sequence': () =>
      I18n.t('Password contains a prohibited sequence of characters.'),
    'pseudonym.password.common': () => I18n.t('Avoid using common passwords like “password123.”'),
    'pseudonym.password.no_digits': () => I18n.t('Password must include at least one number.'),
    'pseudonym.password.no_symbols': () =>
      I18n.t('Password must include at least one special character.'),
    'pseudonym.password.confirmation': () => I18n.t('Passwords do not match.'),
    'pseudonym.password_confirmation.confirmation': () => I18n.t('Passwords do not match.'),

    // taken from ui/shared/normalize-registration-errors/backbone/models/ObserverPairingCodeModel.js
    'pairing_code.code.invalid': () => I18n.t('The pairing code is invalid.'),
  }
}
