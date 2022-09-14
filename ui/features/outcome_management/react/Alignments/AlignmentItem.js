/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {memo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {
  IconAssignmentLine,
  IconRubricLine,
  IconQuizLine,
  IconDiscussionLine,
  IconBankLine
} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {useScope as useI18nScope} from '@canvas/i18n'
import {alignmentShape} from './propTypeShapes'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentItem = ({
  id,
  contentType,
  title,
  url,
  moduleTitle,
  moduleUrl,
  moduleWorkflowState,
  assignmentContentType
}) => {
  const renderIcon = () => {
    if (contentType === 'Rubric') return <IconRubricLine data-testid="alignment-item-rubric-icon" />
    if (contentType === 'AssessmentQuestionBank')
      return <IconBankLine data-testid="alignment-item-bank-icon" />
    if (assignmentContentType === 'quiz')
      return <IconQuizLine data-testid="alignment-item-quiz-icon" />
    if (assignmentContentType === 'discussion')
      return <IconDiscussionLine data-testid="alignment-item-discussion-icon" />
    // by default we show Assignment icon
    return <IconAssignmentLine data-testid="alignment-item-assignment-icon" />
  }

  return (
    <Flex key={id} as="div" alignItems="start" padding="x-small 0 0" data-testid="alignment-item">
      <Flex.Item as="div" size="1.5rem">
        <div
          style={{
            display: 'inline-flex',
            alignSelf: 'center',
            fontSize: '1rem',
            padding: '0.5rem 0 0'
          }}
        >
          {renderIcon()}
        </div>
      </Flex.Item>
      <Flex.Item size="50%" shouldGrow={true}>
        <Flex as="div" direction="column">
          <Flex.Item as="div" padding="xxx-small">
            <Link interaction="enabled" isWithinText={false} href={url} target="_blank">
              <TruncateText>
                <Text size="medium" data-testid="alignment-item-title">
                  {title}
                </Text>
              </TruncateText>
            </Link>
          </Flex.Item>
          <Flex.Item as="div">
            <Flex as="div" padding="xxx-small" alignItems="start">
              <Flex.Item size="3.5rem">
                <Text size="small">{`${I18n.t('Module')}:`}</Text>
              </Flex.Item>
              <Flex.Item size="50%" shouldGrow={true}>
                {moduleTitle && moduleUrl ? (
                  <div style={{paddingTop: '0.14rem'}}>
                    <Text size="small">
                      <Link
                        interaction="enabled"
                        isWithinText={false}
                        href={moduleUrl}
                        target="_blank"
                      >
                        <TruncateText>
                          {moduleWorkflowState === 'unpublished'
                            ? I18n.t('%{moduleTitle} (unpublished)', {moduleTitle})
                            : moduleTitle}
                        </TruncateText>
                      </Link>
                    </Text>
                  </div>
                ) : (
                  <Text size="small" color="secondary">
                    {I18n.t('None')}
                  </Text>
                )}
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

AlignmentItem.propTypes = alignmentShape.isRequired

export default memo(AlignmentItem)
