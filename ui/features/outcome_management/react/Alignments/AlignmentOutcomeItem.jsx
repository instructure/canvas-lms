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

import React, {memo, useState} from 'react'
import PropTypes from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {IconButton} from '@instructure/ui-buttons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconArrowOpenEndLine, IconArrowOpenDownLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {stripHtmlTags} from '@canvas/outcomes/stripHtmlTags'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import AlignmentItem from './AlignmentItem'
import {alignmentShape} from './propTypeShapes'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentOutcomeItem = ({title, description, alignments}) => {
  const [truncated, setTruncated] = useState(true)
  const onClickHandler = () => setTruncated(prevState => !prevState)
  const truncatedDescription = stripHtmlTags(description || '')
  const alignmentsCount = (alignments || []).reduce(
    (acc, alignment) => acc + alignment.alignmentsCount,
    0
  )
  const {isMobileView} = useCanvasContext()

  return (
    <View
      as="div"
      padding={isMobileView ? 'x-small x-small 0 0' : 'x-small 0'}
      borderWidth="0 0 small"
      data-testid="alignment-outcome-item"
    >
      <Flex as="div" alignItems="start">
        <Flex.Item as="div" size={isMobileView ? '2.5rem' : '3rem'}>
          <Flex as="div" alignItems="start" justifyItems="center">
            <Flex.Item>
              <div style={{padding: '0.3125rem 0'}}>
                <IconButton
                  size="small"
                  screenReaderLabel={
                    truncated
                      ? I18n.t('Expand description for outcome %{title}', {title})
                      : I18n.t('Collapse description for outcome %{title}', {title})
                  }
                  withBackground={false}
                  withBorder={false}
                  interaction="enabled"
                  onClick={onClickHandler}
                  data-testid="alignment-summary-outcome-expand-toggle"
                >
                  <div style={{display: 'flex', alignSelf: 'center', fontSize: '0.875rem'}}>
                    {truncated ? (
                      <IconArrowOpenEndLine data-testid="alignment-summary-icon-arrow-right" />
                    ) : (
                      <IconArrowOpenDownLine data-testid="alignment-summary-icon-arrow-down" />
                    )}
                  </div>
                </IconButton>
              </div>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item size="50%" shouldGrow={true}>
          <div style={{padding: '0.625rem 0'}}>
            <Heading level="h4" as="h3">
              <div style={{overflowWrap: 'break-word'}} data-testid="alignment-outcome-item-title">
                {addZeroWidthSpace(title)}
              </div>
            </Heading>
          </div>
        </Flex.Item>
        {!isMobileView && (
          <Flex.Item size="9rem" alignSelf="end">
            <div
              style={{
                padding: '0.4375rem 0.5rem 0 0',
                display: 'flex',
                flexFlow: 'row-reverse nowrap',
              }}
            >
              <Text size="medium" weight="bold" data-testid="outcome-alignments">
                {alignmentsCount}
              </Text>
              <View padding="0 xxx-small 0 0">
                <Text size="medium">{`${I18n.t('Alignments')}:`}</Text>
              </View>
            </div>
          </Flex.Item>
        )}
      </Flex>
      <Flex as="div" alignItems="start">
        <Flex.Item as="div" size={isMobileView ? '2.5rem' : '3rem'} />
        <Flex.Item size="50%" shouldGrow={true}>
          <div style={{paddingBottom: '0.75rem'}}>
            {truncated && truncatedDescription && (
              <View
                as="div"
                padding="0 small 0 0"
                data-testid="alignment-summary-description-truncated"
                className="user_content"
              >
                <PresentationContent>
                  <div
                    style={{
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                    }}
                  >
                    {truncatedDescription}
                  </div>
                </PresentationContent>
                <ScreenReaderContent>{truncatedDescription}</ScreenReaderContent>
              </View>
            )}

            {!truncated && description && (
              <View
                as="div"
                padding="0 small 0 0"
                data-testid="alignment-summary-description-expanded"
                className="user_content"
                dangerouslySetInnerHTML={{__html: description}}
              />
            )}

            {!truncated && alignmentsCount > 0 && (
              <View as="div" padding="0 small small 0" data-testid="outcome-alignments-list">
                {alignments.map(
                  ({
                    _id,
                    contentType,
                    title: alignmentTitle,
                    url,
                    moduleName: moduleTitle,
                    moduleUrl,
                    moduleWorkflowState,
                    assignmentContentType,
                    assignmentWorkflowState,
                    quizItems,
                  }) => (
                    <AlignmentItem
                      id={_id}
                      key={_id}
                      contentType={contentType}
                      title={alignmentTitle}
                      url={url}
                      moduleTitle={moduleTitle}
                      moduleUrl={moduleUrl}
                      moduleWorkflowState={moduleWorkflowState}
                      assignmentContentType={assignmentContentType}
                      assignmentWorkflowState={assignmentWorkflowState}
                      quizItems={quizItems}
                    />
                  )
                )}
              </View>
            )}

            {!truncated && alignmentsCount === 0 && (
              <View as="div" padding="small 0 small">
                <Text size="small" color="secondary">
                  {I18n.t('This outcome has not been aligned')}
                </Text>
              </View>
            )}
          </div>
        </Flex.Item>
      </Flex>
    </View>
  )
}

AlignmentOutcomeItem.propTypes = {
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  alignments: PropTypes.arrayOf(alignmentShape).isRequired,
}

export default memo(AlignmentOutcomeItem)
