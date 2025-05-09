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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {escapeNewLineText} from './utils/rubricUtils'

const I18n = createI18nScope('rubrics-assessment-tray')

type CriteriaReadonlyCommentProps = {
  commentText?: string
}
export const CriteriaReadonlyComment = ({commentText}: CriteriaReadonlyCommentProps) => {
  if (!commentText) return null

  return (
    <Flex
      as="div"
      margin="0"
      direction="column"
      gap="xx-small"
      role="region"
      aria-label={I18n.t('Assessment Comment')}
    >
      <Text weight="bold" id="comment-label">
        {I18n.t('Comment')}
      </Text>
      <Text
        data-testid="comment-preview-text-area"
        themeOverride={{paragraphMargin: 0}}
        dangerouslySetInnerHTML={escapeNewLineText(commentText)}
        aria-labelledby="comment-label"
      />
    </Flex>
  )
}
