/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndLine, IconArrowOpenDownLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!OutcomeManagement'
import OutcomeKebabMenu from './OutcomeKebabMenu'
import OutcomeDescription from './OutcomeDescription'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const ManageOutcomeItem = ({
  _id,
  linkId,
  title,
  description,
  friendlyDescription,
  canManageOutcome,
  isChecked,
  parentGroupId,
  parentGroupTitle,
  onMenuHandler,
  onCheckboxHandler,
  canUnlink
}) => {
  const [truncate, setTruncate] = useState(true)
  const onClickHandler = () => setTruncate(prevState => !prevState)
  const onChangeHandler = () =>
    onCheckboxHandler({_id, linkId, title, canUnlink, parentGroupId, parentGroupTitle})
  const onMenuHandlerWrapper = (_, action) => onMenuHandler(linkId, action)

  // This allows account admins to edit global outcomes
  // within a course. See OUT-1415, OUT-1511
  const {canManage, isAdmin, isCourse} = useCanvasContext()
  const allowAdminEdit = isCourse && canManage && isAdmin

  if (!title) return null

  return (
    <View
      as="div"
      padding="x-small 0"
      borderWidth="0 0 small"
      data-testid="outcome-management-item"
    >
      <Flex as="div" alignItems="start">
        <Flex.Item as="div" size="4.125rem">
          <div style={{padding: '0.3125rem 0'}}>
            <Flex alignItems="center">
              {canManageOutcome && (
                <Flex.Item>
                  <Checkbox
                    label={<ScreenReaderContent>{I18n.t('Select outcome')}</ScreenReaderContent>}
                    value="medium"
                    checked={isChecked}
                    onChange={onChangeHandler}
                  />
                </Flex.Item>
              )}
              <Flex.Item as="div" padding="0 x-small 0 0">
                <IconButton
                  size="small"
                  screenReaderLabel={
                    truncate
                      ? I18n.t('Expand outcome description')
                      : I18n.t('Collapse outcome description')
                  }
                  withBackground={false}
                  withBorder={false}
                  interaction={description || friendlyDescription ? 'enabled' : 'disabled'}
                  onClick={onClickHandler}
                >
                  <div style={{display: 'flex', alignSelf: 'center', fontSize: '0.875rem'}}>
                    {truncate ? (
                      <IconArrowOpenEndLine data-testid="icon-arrow-right" />
                    ) : (
                      <IconArrowOpenDownLine data-testid="icon-arrow-down" />
                    )}
                  </div>
                </IconButton>
              </Flex.Item>
            </Flex>
          </div>
        </Flex.Item>
        <Flex.Item align="start" size="50%" shouldGrow>
          <div style={{padding: '0.625rem 0'}}>
            <Heading level="h4" data-testid="outcome-management-item-title">
              <div style={{overflowWrap: 'break-word'}}>{addZeroWidthSpace(title)}</div>
            </Heading>
          </div>
        </Flex.Item>
        {(canManageOutcome || allowAdminEdit) && (
          <Flex.Item>
            <OutcomeKebabMenu
              canDestroy={canUnlink}
              menuTitle={I18n.t('Outcome Menu')}
              onMenuHandler={onMenuHandlerWrapper}
            />
          </Flex.Item>
        )}
      </Flex>
      <Flex as="div" alignItems="start">
        <Flex.Item size="4.125rem" />
        <Flex.Item size="50%" shouldGrow>
          {(description || friendlyDescription) && (
            <View as="div" padding="0 0 x-small">
              <OutcomeDescription
                withExternalControl
                description={description}
                truncate={truncate}
                onClickHandler={onClickHandler}
                friendlyDescription={friendlyDescription}
              />
            </View>
          )}
        </Flex.Item>
      </Flex>
    </View>
  )
}

ManageOutcomeItem.propTypes = {
  _id: PropTypes.string.isRequired,
  linkId: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  friendlyDescription: PropTypes.string,
  isChecked: PropTypes.bool.isRequired,
  parentGroupId: PropTypes.string.isRequired,
  parentGroupTitle: PropTypes.string.isRequired,
  onMenuHandler: PropTypes.func.isRequired,
  onCheckboxHandler: PropTypes.func.isRequired,
  canUnlink: PropTypes.bool.isRequired,
  canManageOutcome: PropTypes.bool.isRequired
}

export default memo(ManageOutcomeItem)
