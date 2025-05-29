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

import PropTypes from 'prop-types'
import React from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_survey_link')

export const SurveyLinkBox = ({text, marginTop}) => {
  if (!window.ENV?.FEATURES?.discussion_ai_survey_link || window.ENV?.current_user_is_student) {
    return null
  }

  return (
    <View as="div" background="secondary" padding="small" margin={`${marginTop || '0'} 0 0 0`}>
      <Text
        data-testid="discussion-ai-survey-text"
        dangerouslySetInnerHTML={{
          __html: text,
        }}
      ></Text>
      <Link href="https://inst.bid/ai/feedback/" target="_blank" margin="0 0 0 x-small">
        {I18n.t('Please share your feedback')}
      </Link>
    </View>
  )
}

SurveyLinkBox.propTypes = {
  text: PropTypes.object,
  marginTop: PropTypes.string,
}
