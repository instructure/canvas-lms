/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'

const I18n = createI18nScope('pseudonym')

extend(Pseudonym, Backbone.Model)

function Pseudonym() {
  return Pseudonym.__super__.constructor.apply(this, arguments)
}

Pseudonym.prototype.errorMap = function (policy) {
  if (policy == null) {
    policy = {}
  }
  return {
    unique_id: {
      too_short: I18n.t('errors.required', 'Required'),
      too_long: I18n.t('errors.too_long', "Can't exceed %{max} characters", {
        max: 100,
      }),
      invalid: I18n.t(
        'errors.invalid',
        'May only contain letters, numbers, or the following: %{characters}',
        {
          characters: '. + - _ @ =',
        },
      ),
      taken: I18n.t('errors.taken', 'Already in use'),
      bad_credentials: I18n.t('errors.bad_credentials', 'Invalid username or password'),
      not_email: I18n.t('errors.not_email', 'Not a valid email address'),
    },
    sis_user_id: {
      too_long: I18n.t('errors.too_long', "Can't exceed %{max} characters", {
        max: 255,
      }),
      taken: I18n.t('errors.sis_taken', 'The SIS ID is already in use'),
    },
    integration_id: {
      too_long: I18n.t('errors.too_long', "Can't exceed %{max} characters", {
        max: 255,
      }),
      taken: I18n.t('errors.integration_taken', 'The Integration ID is already in use'),
    },
    password: {
      too_short: I18n.t('errors.too_short', 'Must be at least %{min} characters', {
        min: policy?.minimum_character_length,
      }),
      too_long: I18n.t('errors.too_long', "Can't exceed %{max} characters", {
        max: 255,
      }),
      repeated: I18n.t(
        'errors.repeated',
        "Can't have the same character more than %{max} times in a row",
        {
          max: policy?.max_repeats,
        },
      ),
      sequence: I18n.t(
        'errors.sequence',
        "Can't incude a run of more than %{max} characters (e.g. abcdef)",
        {
          max: policy?.max_sequence,
        },
      ),
      common: I18n.t('errors.common', 'Can\'t use common passwords (e.g. "password")'),
      no_digits: I18n.t('errors.no_digits', 'Must include at least one number'),
      no_symbols: I18n.t('errors.no_symbols', 'Must include at least one symbol'),
      confirmation: I18n.t('errors.mismatch', "Doesn't match"),
      unexpected: I18n.t(
        'errors.unexpected',
        'An unexpected error occurred. Please try again later.',
      ),
    },
    password_confirmation: {
      confirmation: I18n.t('errors.mismatch', "Doesn't match"),
    },
  }
}

Pseudonym.prototype.normalizeErrors = function (errors, policy) {
  let e, i, j, len, len1, ref, ref1, ref2, too_short, type
  if (errors) {
    ref = ['unique_id', 'password']
    for (i = 0, len = ref.length; i < len; i++) {
      type = ref[i]
      if (!(((ref1 = errors[type]) != null ? ref1.length : void 0) > 1)) {
        continue
      }
      too_short = null
      ref2 = errors[type]
      for (j = 0, len1 = ref2.length; j < len1; j++) {
        e = ref2[j]
        if (e.type === 'too_short') {
          too_short = e
        }
      }
      if (too_short) {
        errors[type] = [too_short]
      }
    }
  }
  return Pseudonym.__super__.normalizeErrors.call(this, errors, policy)
}

export default Pseudonym
