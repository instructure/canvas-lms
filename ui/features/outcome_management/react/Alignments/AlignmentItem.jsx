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
  IconQuizSolid,
  IconDiscussionLine,
  IconBankLine,
} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {alignmentShape} from './propTypeShapes'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentItem = ({
  id,
  contentType,
  title,
  url,
  moduleTitle,
  moduleUrl,
  moduleWorkflowState,
  assignmentContentType,
  assignmentWorkflowState,
  quizItems,
}) => {
  const renderIcon = () => {
    let icon
    let screenReaderText
    if (contentType === 'Rubric') {
      icon = <IconRubricLine data-testid="alignment-item-rubric-icon" />
      screenReaderText = I18n.t('Rubric')
    } else if (contentType === 'AssessmentQuestionBank') {
      icon = <IconBankLine data-testid="alignment-item-bank-icon" />
      screenReaderText = I18n.t('Assessment Question Bank')
    } else if (assignmentContentType === 'quiz') {
      icon = <IconQuizLine data-testid="alignment-item-quiz-icon" />
      screenReaderText = I18n.t('Quiz')
    } else if (assignmentContentType === 'discussion') {
      icon = <IconDiscussionLine data-testid="alignment-item-discussion-icon" />
      screenReaderText = I18n.t('Discussion')
    } else if (assignmentContentType === 'new_quiz') {
      icon = <IconQuizSolid data-testid="alignment-item-new-quiz-icon" />
      screenReaderText = I18n.t('New Quiz')
    } else {
      // by default we show Assignment icon
      icon = <IconAssignmentLine data-testid="alignment-item-assignment-icon" />
      screenReaderText = I18n.t('Assignment')
    }
    return (
      <div
        style={{
          display: 'inline-flex',
          alignSelf: 'center',
          fontSize: '1rem',
          padding: '0.5rem 0 0',
        }}
      >
        {icon}
        <div style={{position: 'relative'}}>
          <ScreenReaderContent>{screenReaderText}</ScreenReaderContent>
        </div>
      </div>
    )
  }

  const shouldRenderQuizItems = assignmentContentType === 'new_quiz' && quizItems?.length > 0

  const renderQuizItems = items => (
    <Flex as="div" direction="column" padding="xxx-small" alignItems="start">
      <Flex.Item as="div">
        <div style={{paddingTop: '0.14rem'}}>
          <Text size="small" weight="bold" data-testid="aligned-questions">
            {I18n.t('Aligned Questions')}
          </Text>
        </div>
      </Flex.Item>
      {items.map(({_id, title}, ind) => (
        <Flex.Item as="div" key={`${_id}`}>
          <Flex as="div" padding="xxx-small" alignItems="start">
            <Flex.Item size="1.5rem">
              <Text size="small" weight="bold">{`${ind + 1}.`}</Text>
            </Flex.Item>
            <Flex.Item as="div" size="50%" shouldGrow={true}>
              <div style={{paddingTop: '0.14rem'}}>
                <Text size="small" data-testid="aligned-question-title">
                  <TruncateText>{title}</TruncateText>
                </Text>
              </div>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      ))}
    </Flex>
  )

  return (
    <Flex key={id} as="div" alignItems="start" padding="x-small 0 0" data-testid="alignment-item">
      <Flex.Item as="div" size="1.5rem">
        {renderIcon()}
      </Flex.Item>
      <Flex.Item size="50%" shouldGrow={true}>
        <Flex as="div" direction="column">
          <Flex.Item as="div" padding="xxx-small">
            <a href={url} target="_blank" rel="noreferrer">
              <TruncateText>
                <Text size="medium" data-testid="alignment-item-title">
                  {assignmentWorkflowState === 'unpublished'
                    ? I18n.t('%{title} (unpublished)', {title})
                    : title}
                </Text>
              </TruncateText>
            </a>
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
                      <a href={moduleUrl} target="_blank" rel="noreferrer">
                        <TruncateText>
                          {moduleWorkflowState === 'unpublished'
                            ? I18n.t('%{moduleTitle} (unpublished)', {moduleTitle})
                            : moduleTitle}
                        </TruncateText>
                      </a>
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
          {shouldRenderQuizItems && renderQuizItems(quizItems)}
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

AlignmentItem.propTypes = alignmentShape.isRequired

export default memo(AlignmentItem)
