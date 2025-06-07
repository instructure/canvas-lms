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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconCoursesLine} from '@instructure/ui-icons'

import apiUserContent from '@canvas/util/jquery/apiUserContent'

const I18n = createI18nScope('important_info')

export interface ImportantInfoData {
  courseId: string
  courseName: string
  canEdit: boolean
  content: string
}

interface ImportantInfoEditHeaderProps {
  children: React.ReactNode
  canEdit: boolean
  courseName: string
  courseId: string
  margin?: string
}

export const ImportantInfoEditHeader: React.FC<ImportantInfoEditHeaderProps> = ({
  children,
  canEdit,
  courseName,
  courseId,
  margin,
}) => (
  <Flex alignItems="center" justifyItems="space-between" margin={margin}>
    <Flex.Item>{children}</Flex.Item>
    {canEdit && (
      <Flex.Item>
        <IconButton
          data-testid="important-info-edit"
          screenReaderLabel={I18n.t('Edit important info for %{courseName}', {
            courseName,
          })}
          withBackground={false}
          withBorder={false}
          href={`/courses/${courseId}/assignments/syllabus`}
        >
          <IconEditLine />
        </IconButton>
      </Flex.Item>
    )}
  </Flex>
)

interface ImportantInfoProps {
  showTitle?: boolean
  titleMargin?: string
  infoDetails?: ImportantInfoData
}

const ImportantInfo: React.FC<ImportantInfoProps> = ({
  showTitle = false,
  titleMargin,
  infoDetails,
}) => {
  return (
    <>
      {showTitle && infoDetails && (
        <ImportantInfoEditHeader
          canEdit={infoDetails.canEdit}
          courseName={infoDetails.courseName}
          courseId={infoDetails.courseId}
          margin={titleMargin}
        >
          <Heading level="h3">
            <span style={{fontSize: '1.5rem', marginRight: '0.75rem'}}>
              <IconCoursesLine />
            </span>
            {infoDetails.courseName}
          </Heading>
        </ImportantInfoEditHeader>
      )}
      <div
        className="user_content"
        /* html sanitized by server */
        dangerouslySetInnerHTML={{__html: apiUserContent.convert(infoDetails?.content)}}
      />
    </>
  )
}

export default ImportantInfo
