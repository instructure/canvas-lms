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
import I18n from 'i18n!k5_ImportantInfo'
import PropTypes from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconCoursesLine} from '@instructure/ui-icons'

import apiUserContent from '@canvas/util/jquery/apiUserContent'
import LoadingSkeleton from './LoadingSkeleton'

export const ImportantInfoShape = {
  courseId: PropTypes.string.isRequired,
  courseName: PropTypes.string.isRequired,
  canEdit: PropTypes.bool.isRequired,
  content: PropTypes.string.isRequired
}

export const ImportantInfoEditHeader = ({children, canEdit, courseName, courseId, margin}) => (
  <Flex alignItems="center" justifyItems="space-between" margin={margin}>
    <Flex.Item>{children}</Flex.Item>
    {canEdit && (
      <Flex.Item>
        <IconButton
          screenReaderLabel={I18n.t('Edit important info for %{courseName}', {
            courseName
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

ImportantInfoEditHeader.propTypes = {
  children: PropTypes.node.isRequired,
  canEdit: PropTypes.bool.isRequired,
  courseName: PropTypes.string.isRequired,
  courseId: PropTypes.string.isRequired,
  margin: PropTypes.string
}

const ImportantInfo = ({isLoading, showTitle = false, titleMargin, infoDetails}) => {
  return isLoading ? (
    <LoadingSkeleton
      height="8em"
      width="100%"
      margin="small 0 0"
      screenReaderLabel={I18n.t('Loading important info')}
    />
  ) : (
    <>
      {showTitle && (
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
        dangerouslySetInnerHTML={{__html: apiUserContent.convert(infoDetails.content)}}
      />
    </>
  )
}

ImportantInfo.propTypes = {
  isLoading: PropTypes.bool.isRequired,
  showTitle: PropTypes.bool,
  titleMargin: PropTypes.string,
  infoDetails: PropTypes.shape(ImportantInfoShape)
}

export default ImportantInfo
