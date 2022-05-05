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

const I18n = useI18nScope('AlignmentSummary')

const AlignmentOutcomeItem = ({title, description, alignmentCount}) => {
  const [truncated, setTruncated] = useState(true)
  const onClickHandler = () => setTruncated(prevState => !prevState)
  const truncatedDescription = stripHtmlTags(description || '')

  return (
    <View as="div" padding="x-small 0" borderWidth="0 0 small" data-testid="alignment-outcome-item">
      <Flex as="div" alignItems="start">
        <Flex.Item as="div" size="3rem">
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
        <Flex.Item size="50%" shouldGrow>
          <div style={{padding: '0.625rem 0'}}>
            <Heading level="h4">
              <div style={{overflowWrap: 'break-word'}}>{addZeroWidthSpace(title)}</div>
            </Heading>
          </div>
          <div style={{paddingBottom: '0.75rem'}}>
            {truncated && truncatedDescription && (
              <View
                as="div"
                padding="0 small 0 0"
                data-testid="alignment-summary-description-truncated"
              >
                <PresentationContent>
                  <div
                    style={{
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis'
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
                dangerouslySetInnerHTML={{__html: description}}
              />
            )}
          </div>
        </Flex.Item>
        <Flex.Item size="7rem" alignSelf="end">
          <div
            style={{
              padding: '0.4375rem 0.5rem 0 0',
              display: 'flex',
              flexFlow: 'row-reverse nowrap'
            }}
          >
            <Text size="medium" weight="bold">
              {alignmentCount}
            </Text>
            <View padding="0 xxx-small 0 0">
              <Text size="medium">{`${I18n.t('Aligned')}:`}</Text>
            </View>
          </div>
        </Flex.Item>
      </Flex>
    </View>
  )
}

AlignmentOutcomeItem.propTypes = {
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  alignmentCount: PropTypes.number.isRequired
}

export default memo(AlignmentOutcomeItem)
