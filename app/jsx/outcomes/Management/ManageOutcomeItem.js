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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndLine, IconArrowOpenDownLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import I18n from 'i18n!OutcomeManagement'
import OutcomeKebabMenu from './OutcomeKebabMenu'
import OutcomeDescription from './OutcomeDescription'
import {addZeroWidthSpace} from '../../shared/helpers/addZeroWidthSpace'

const ManageOutcomeItem = ({
  id,
  title,
  description,
  isFirst,
  isChecked,
  onMenuHandler,
  onCheckboxHandler
}) => {
  const [truncate, setTruncate] = useState(true)
  const onClickHandler = () => setTruncate(prevState => !prevState)
  const onChangeHandler = () => onCheckboxHandler(id)
  const onMenuHandlerWrapper = (_, action) => onMenuHandler(id, action)

  if (!title) return null

  return (
    <View
      as="div"
      padding="x-small 0"
      borderWidth={isFirst ? 'small 0' : '0 0 small'}
      data-testid={isFirst ? 'outcome-with-top-bottom-border' : 'outcome-with-bottom-border'}
    >
      <Flex as="div" alignItems="start">
        <Flex.Item as="div" size="4.125rem">
          <div style={{padding: '0.3125rem 0'}}>
            <Flex alignItems="center">
              <Flex.Item>
                <Checkbox
                  label={<ScreenReaderContent>{I18n.t('Select outcome')}</ScreenReaderContent>}
                  value="medium"
                  checked={isChecked}
                  onChange={onChangeHandler}
                />
              </Flex.Item>
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
                  interaction={description ? 'enabled' : 'disabled'}
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
            <Heading level="h4">
              <div style={{overflowWrap: 'break-word'}}>{addZeroWidthSpace(title)}</div>
            </Heading>
          </div>
        </Flex.Item>
        <Flex.Item>
          <OutcomeKebabMenu
            menuTitle={I18n.t('Outcome Menu')}
            onMenuHandler={onMenuHandlerWrapper}
          />
        </Flex.Item>
      </Flex>
      <Flex as="div" alignItems="start">
        <Flex.Item size="4.125rem" />
        <Flex.Item size="50%" shouldGrow>
          {description && (
            <View as="div" padding="0 0 x-small">
              <OutcomeDescription
                withExternalControl
                description={description}
                truncate={truncate}
                onClickHandler={onClickHandler}
              />
            </View>
          )}
        </Flex.Item>
      </Flex>
    </View>
  )
}

ManageOutcomeItem.defaultProps = {
  isFirst: false
}

ManageOutcomeItem.propTypes = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  isFirst: PropTypes.bool,
  isChecked: PropTypes.bool.isRequired,
  onMenuHandler: PropTypes.func.isRequired,
  onCheckboxHandler: PropTypes.func.isRequired
}

export default ManageOutcomeItem
