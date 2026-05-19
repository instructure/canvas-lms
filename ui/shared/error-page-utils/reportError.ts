/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {ErrorReport} from '@instructure/platform-generic-error-page'
import type {TranslationBridge} from '@instructure/platform-provider'

const I18n = createI18nScope('generic_error_page')
const I18nNotFound = createI18nScope('not_found_index')

export const canvasErrorPageTranslations = {
  somethingBroke: () => I18n.t('Sorry, Something Broke'),
  helpUsImprove: () => I18n.t('Help us improve by telling us what happened'),
  reportIssue: () => I18n.t('Report Issue'),
  loading: () => I18n.t('Loading'),
  commentSubmitted: () => I18n.t('Comment submitted!'),
  commentFailed: () => I18n.t('Comment failed to post! Please try again later.'),
  whatHappened: () => I18n.t('What happened?'),
  yourEmailAddress: () => I18n.t('Your Email Address'),
  emailPlaceholder: () => I18n.t('email@example.com'),
  submit: () => I18n.t('Submit'),
} satisfies TranslationBridge

export const canvasNotFoundTranslations = {
  title: () => I18nNotFound.t('Whoops... Looks like nothing is here!'),
  description: () => I18nNotFound.t("We couldn't find that page!"),
}

export async function reportError(report: ErrorReport): Promise<{logged: boolean}> {
  const {json} = await doFetchApi<{logged: boolean; id: string}>({
    path: '/error_reports',
    method: 'POST',
    body: {
      error: {
        subject: report.subject,
        category: report.category,
        exception_message: report.message,
        message: report.message,
        url: report.url,
        comments: report.comments,
        email: report.email,
        backtrace: report.backtrace,
        user_roles: window.ENV?.current_user_roles?.join(','),
      },
    },
  })
  return {logged: json?.logged ?? false}
}
