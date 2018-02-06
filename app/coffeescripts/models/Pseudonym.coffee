#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!pseudonym'
  'Backbone'
], (I18n, Backbone) ->

  class Pseudonym extends Backbone.Model

    errorMap: (policy={}) ->
      unique_id:
        too_short:    I18n.t("errors.required", "Required")
        too_long:     I18n.t("errors.too_long", "Can't exceed %{max} characters", {max: 100})
        invalid:      I18n.t("errors.invalid", "May only contain letters, numbers, or the following: %{characters}", {characters: ". + - _ @ ="})
        taken:        I18n.t("errors.taken", "Already in use")
        bad_credentials: I18n.t("errors.bad_credentials", "Invalid username or password")
        not_email:    I18n.t("errors.not_email", "Not a valid email address")
      sis_user_id:
        too_long:     I18n.t("errors.too_long", "Can't exceed %{max} characters", {max: 255})
        taken:        I18n.t("errors.sis_taken", "The SIS ID is already in use")
      password:
        too_short:    I18n.t("errors.too_short", "Must be at least %{min} characters", {min: policy.min_length})
        sequence:     I18n.t("errors.sequence", "Can't incude a run of more than %{max} characters (e.g. abcdef)", {max: policy.max_sequence})
        common:       I18n.t("errors.common", "Can't use common passwords (e.g. \"password\")")
        repeated:     I18n.t("errors.repeated", "Can't have the same character more than %{max} times in a row", {max: policy.max_repeats})
        confirmation: I18n.t("errors.mismatch", "Doesn't match")
        too_long:     I18n.t("errors.too_long", "Can't exceed %{max} characters", {max: 255})
      password_confirmation:
        confirmation: I18n.t("errors.mismatch", "Doesn't match")

    normalizeErrors: (errors, policy) ->
      if errors
        for type in ['unique_id', 'password'] when errors[type]?.length > 1
          # if there are multiple errors and one is "too_short", just show that
          too_short = null
          too_short = e for e in errors[type] when e.type is 'too_short'
          errors[type] = [too_short] if too_short
      super errors, policy
