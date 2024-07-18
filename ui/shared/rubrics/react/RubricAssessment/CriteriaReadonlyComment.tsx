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
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {escapeNewLineText} from './utils/rubricUtils'

const I18n = useI18nScope('rubrics-assessment-tray')

type CriteriaReadonlyCommentProps = {
  commentText?: string
}
export const CriteriaReadonlyComment = ({commentText}: CriteriaReadonlyCommentProps) => {
  return (
    <View as="div" margin="0">
      {commentText && (
        <View as="div" margin="0">
          <Text weight="bold">{I18n.t('Comment')}</Text>
        </View>
      )}
      <Text
        data-testid="comment-preview-text-area"
        themeOverride={{paragraphMargin: 0}}
        dangerouslySetInnerHTML={escapeNewLineText(commentText ?? '')}
      />
    </View>
  )
}
