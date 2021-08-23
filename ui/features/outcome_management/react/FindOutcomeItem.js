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
  IconAddSolid
} from '@instructure/ui-icons'
import I18n from 'i18n!OutcomeManagement'
import OutcomeDescription from './Management/OutcomeDescription'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {Spinner} from '@instructure/ui-spinner'
import {IMPORT_PENDING, IMPORT_COMPLETED} from '@canvas/outcomes/react/hooks/useOutcomesImport'

const FindOutcomeItem = ({
  id,
  title,
  description,
  isImported,
  importGroupStatus,
  importOutcomeStatus,
  sourceContextId,
  sourceContextType,
  importOutcomeHandler
}) => {
  const [truncate, setTruncate] = useState(true)
  const onClickHandler = () => description && setTruncate(prevState => !prevState)
  const {isMobileView} = useCanvasContext()
  const IconArrowOpenEnd = isMobileView ? IconArrowOpenEndSolid : IconArrowOpenEndLine
  const IconArrowOpenDown = isMobileView ? IconArrowOpenDownSolid : IconArrowOpenDownLine
  const importStatus = [importGroupStatus, importOutcomeStatus]
  const isOutcomeImported = isImported || importStatus.includes(IMPORT_COMPLETED)
  const onAddHandler = () => importOutcomeHandler(id, false, sourceContextId, sourceContextType)

  const checkbox = (
    <Flex.Item size={isMobileView ? '' : '6.75rem'} alignSelf="end">
      <div
        style={{
          padding: isMobileView ? '0' : description ? '1.2815rem 0 0' : '0.313rem 0 0',
          marginRight: isMobileView ? '-0.5rem' : '0',
          display: 'flex',
          flexFlow: 'row-reverse nowrap'
        }}
      >
        {importStatus.includes(IMPORT_PENDING) ? (
          <View as="div" margin="0 medium" data-testid="outcome-import-pending">
            <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
          </View>
        ) : (
          <Button
            interaction={isOutcomeImported ? 'disabled' : 'enabled'}
            size="small"
            margin={isMobileView ? '0' : '0 x-small 0 0'}
            renderIcon={IconAddSolid}
            onClick={onAddHandler}
            data-testid="add-find-outcome-item"
          >
            {isOutcomeImported ? I18n.t('Added') : I18n.t('Add')}
          </Button>
        )}
      </div>
    </Flex.Item>
  )

  if (!title) return null

  return (
    <View
      as="div"
      padding={isMobileView ? 'small 0 x-small' : 'small 0'}
      borderWidth="0 0 small"
      data-testid="find-outcome-item"
    >
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
  isImported: PropTypes.bool.isRequired,
  importGroupStatus: PropTypes.string.isRequired,
  importOutcomeStatus: PropTypes.string,
  sourceContextId: PropTypes.string,
  sourceContextType: PropTypes.string,
  importOutcomeHandler: PropTypes.func.isRequired
}

export default memo(FindOutcomeItem)
