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

import React, {useState, memo} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconButton, Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {
  IconArrowOpenEndLine,
  IconArrowOpenDownLine,
  IconArrowOpenEndSolid,
  IconArrowOpenDownSolid,
  IconAddLine
} from '@instructure/ui-icons'
import I18n from 'i18n!OutcomeManagement'
import OutcomeDescription from './Management/OutcomeDescription'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const FindOutcomeItem = ({id, title, description, isAdded, onAddClickHandler}) => {
  const [truncate, setTruncate] = useState(true)
  // NOTE: addedOutcome state will not be needed once refetching of groups/outcomes
  // is completed.  See OUT-4521 & OUT-4559
  const [addedOutcome, setAddedOutcome] = useState(isAdded)
  const [buttonMessage, setButtonMessage] = useState(isAdded ? I18n.t('Added') : I18n.t('Add'))
  const onClickHandler = () => description && setTruncate(prevState => !prevState)
  const {isMobileView} = useCanvasContext()
  const IconArrowOpenEnd = isMobileView ? IconArrowOpenEndSolid : IconArrowOpenEndLine
  const IconArrowOpenDown = isMobileView ? IconArrowOpenDownSolid : IconArrowOpenDownLine

  const onButtonClick = () => {
    setAddedOutcome(true)
    setButtonMessage(I18n.t('Added'))
    onAddClickHandler(id)
  }

  const checkbox = (
    <Flex.Item size={isMobileView ? '' : '5rem'} alignSelf="end">
      <div
        style={{
          padding: isMobileView
            ? '0'
            : description && addedOutcome
            ? '1.2815rem 0 0 0'
            : description
            ? '1.2815rem 0 0 1rem'
            : addedOutcome
            ? '0.313rem 0 0 0'
            : '0.313rem 0 0 1rem',
          marginRight: isMobileView ? '-12px' : '0'
        }}
      >
        <Button
          interaction={addedOutcome ? 'disabled' : 'enabled'}
          size="small"
          margin="0 x-small 0 0"
          renderIcon={IconAddLine}
          onClick={onButtonClick}
        >
          {buttonMessage}
        </Button>
      </div>
    </Flex.Item>
  )

  if (!title) return null

  return (
    <View as="div" padding={isMobileView ? 'small 0 x-small' : 'small 0'} borderWidth="0 0 small">
      <Flex as="div" alignItems="start">
        <Flex.Item as="div" size={isMobileView ? '' : '3rem'}>
          <Flex as="div" alignItems="start" justifyItems="center">
            <Flex.Item>
              <div style={{padding: '0.3125rem 0'}}>
                <IconButton
                  size="small"
                  screenReaderLabel={
                    truncate
                      ? I18n.t('Expand outcome description')
                      : I18n.t('Collapse outcome description')
                  }
                  withBackground={false}
                  withBorder={false}
                  interaction={description ? 'enabled' : 'disabled'}
                  onClick={onClickHandler}
                >
                  <div style={{display: 'flex', alignSelf: 'center', fontSize: '0.875rem'}}>
                    {truncate ? (
                      <IconArrowOpenEnd data-testid="icon-arrow-right" />
                    ) : (
                      <IconArrowOpenDown data-testid="icon-arrow-down" />
                    )}
                  </div>
                </IconButton>
              </div>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item size="50%" shouldGrow padding={isMobileView ? '0 0 0 x-small' : '0'}>
          <div
            style={{
              padding: isMobileView ? '0 0 0.5rem 0' : '0.625rem 0',
              display: 'flex',
              justifyContent: 'space-between'
            }}
          >
            {isMobileView ? (
              <div style={{padding: '0.35rem 0px 0px 0px'}}>
                <Text wrap="break-word" weight="bold">
                  {addZeroWidthSpace(title)}
                </Text>
              </div>
            ) : (
              <Heading level="h4">
                <div style={{overflowWrap: 'break-word'}}>{addZeroWidthSpace(title)}</div>
              </Heading>
            )}
            {isMobileView && checkbox}
          </div>
          {description && (
            <div style={{paddingBottom: '0.75rem'}}>
              <OutcomeDescription
                withExternalControl
                description={description}
                truncate={truncate}
                onClickHandler={onClickHandler}
              />
            </div>
          )}
        </Flex.Item>
        {!isMobileView && checkbox}
      </Flex>
    </View>
  )
}

FindOutcomeItem.propTypes = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string,
  description: PropTypes.string,
  isAdded: PropTypes.bool.isRequired,
  onAddClickHandler: PropTypes.func.isRequired
}

export default memo(FindOutcomeItem)
