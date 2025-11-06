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

import {useScope as createI18nScope} from '@canvas/i18n'
import {AllocationRuleType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'

const I18n = createI18nScope('peer_review_allocation_rules')

/**
 * Formats a full rule description including both the assessor and assessee names.
 * Used for screen reader announcements.
 * Example: "Student A must review Student B"
 */
export const formatFullRuleDescription = (rule: AllocationRuleType): string => {
  const {mustReview, reviewPermitted, appliesToAssessor, assessor, assessee} = rule
  if (appliesToAssessor) {
    if (mustReview && reviewPermitted) {
      return I18n.t('%{assessor} must review %{assessee}', {
        assessor: assessor.name,
        assessee: assessee.name,
      })
    } else if (mustReview && !reviewPermitted) {
      return I18n.t('%{assessor} must not review %{assessee}', {
        assessor: assessor.name,
        assessee: assessee.name,
      })
    } else if (!mustReview && reviewPermitted) {
      return I18n.t('%{assessor} should review %{assessee}', {
        assessor: assessor.name,
        assessee: assessee.name,
      })
    } else {
      return I18n.t('%{assessor} should not review %{assessee}', {
        assessor: assessor.name,
        assessee: assessee.name,
      })
    }
  } else {
    if (mustReview && reviewPermitted) {
      return I18n.t('%{assessee} must be reviewed by %{assessor}', {
        assessee: assessee.name,
        assessor: assessor.name,
      })
    } else if (mustReview && !reviewPermitted) {
      return I18n.t('%{assessee} must not be reviewed by %{assessor}', {
        assessee: assessee.name,
        assessor: assessor.name,
      })
    } else if (!mustReview && reviewPermitted) {
      return I18n.t('%{assessee} should be reviewed by %{assessor}', {
        assessee: assessee.name,
        assessor: assessor.name,
      })
    } else {
      return I18n.t('%{assessee} should not be reviewed by %{assessor}', {
        assessee: assessee.name,
        assessor: assessor.name,
      })
    }
  }
}

/**
 * Formats a rule description with only the action and subject.
 * Used for displaying on allocation rule cards where the main student is already visible.
 * Example: "Must review Student B"
 */
export const formatRuleDescription = (rule: AllocationRuleType): string => {
  const {mustReview, reviewPermitted, appliesToAssessor, assessor, assessee} = rule
  if (appliesToAssessor) {
    if (mustReview && reviewPermitted) {
      return I18n.t('Must review %{subject}', {subject: assessee.name})
    } else if (mustReview && !reviewPermitted) {
      return I18n.t('Must not review %{subject}', {subject: assessee.name})
    } else if (!mustReview && reviewPermitted) {
      return I18n.t('Should review %{subject}', {subject: assessee.name})
    } else {
      return I18n.t('Should not review %{subject}', {subject: assessee.name})
    }
  } else {
    if (mustReview && reviewPermitted) {
      return I18n.t('Must be reviewed by %{subject}', {subject: assessor.name})
    } else if (mustReview && !reviewPermitted) {
      return I18n.t('Must not be reviewed by %{subject}', {subject: assessor.name})
    } else if (!mustReview && reviewPermitted) {
      return I18n.t('Should be reviewed by %{subject}', {subject: assessor.name})
    } else {
      return I18n.t('Should not be reviewed by %{subject}', {subject: assessor.name})
    }
  }
}
