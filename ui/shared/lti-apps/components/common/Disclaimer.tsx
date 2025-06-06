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
import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('lti_registrations')

function Disclaimer() {
  const baseDisclaimer = I18n.t(
    'Apps offered in the Canvas Apps library are not reviewed or otherwise vetted by Instructure. We encourage you to review the AI, privacy, and security practices of each provider before connecting to your Canvas LMS account. The information on this page is provided by the respective Partner and pertains to the latest app version available on the Apps page. These policies and procedures are not controlled by Instructure. Partners are solely responsible for the accuracy of the information provided.',
  )

  const isEnglish = (I18n.currentLocale()?.split('-')[0] || 'en') === 'en'
  const isAiTranslationFeatureEnabled = ENV?.FEATURES?.lti_apps_page_ai_translation ?? false
  const showTranslationNote = isAiTranslationFeatureEnabled && !isEnglish
  const translationNote = I18n.t(
    'The translations in this content may be generated by humans or AI. Use your discretion when relying on translated content.',
  )

  return (
    <View as="div">
      <Text color="secondary" size="small">
        {baseDisclaimer}
        {showTranslationNote && ' ' + translationNote}
      </Text>
    </View>
  )
}

export default Disclaimer
