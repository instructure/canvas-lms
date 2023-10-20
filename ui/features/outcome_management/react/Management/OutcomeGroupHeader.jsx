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

import React, {useEffect, useRef} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {IconButton} from '@instructure/ui-buttons'
import {IconMiniArrowDownLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import OutcomeKebabMenu from './OutcomeKebabMenu'

const I18n = useI18nScope('OutcomeManagement')

const OutcomeGroupHeader = ({
  title,
  minWidth,
  onMenuHandler,
  canManage,
  description,
  hideOutcomesView,
}) => {
  const {isMobileView} = useCanvasContext()
  const hideButtonRef = useRef()

  useEffect(() => {
    if (isMobileView) {
      hideButtonRef.current.focus()
    }
  }, [isMobileView])

  return (
    <View as="div">
      <Flex as="div" alignItems={isMobileView ? 'center' : 'start'}>
        <Flex.Item size={minWidth} shouldGrow={true}>
          <div style={{padding: isMobileView ? '0' : '0.21875rem 0'}}>
            {isMobileView ? (
              <div style={{overflowWrap: 'break-word', display: 'inline-block'}}>
                <Text weight="bold">
                  {title
                    ? I18n.t('%{title}', {title: addZeroWidthSpace(title)})
                    : I18n.t('Outcomes')}
                </Text>
                <IconButton
                  size="small"
                  withBackground={false}
                  withBorder={false}
                  onClick={hideOutcomesView}
                  screenReaderLabel={I18n.t('Select another group')}
                  elementRef={el => {
                    hideButtonRef.current = el
                  }}
                  margin="x-small"
                >
                  {IconMiniArrowDownLine}
                </IconButton>
              </div>
            ) : (
              <Heading level="h2">
                <div style={{overflowWrap: 'break-word'}}>
                  {title
                    ? I18n.t('%{title} Outcomes', {title: addZeroWidthSpace(title)})
                    : I18n.t('Outcomes')}
                </div>
              </Heading>
            )}
          </div>
        </Flex.Item>
        {canManage && (
          <Flex.Item>
            <OutcomeKebabMenu
              canDestroy={true}
              isGroup={true}
              menuTitle={I18n.t('Menu for group %{title}', {title})}
              onMenuHandler={onMenuHandler}
              groupDescription={description}
            />
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

OutcomeGroupHeader.defaultProps = {
  minWidth: 'auto',
  title: '',
  description: '',
  canManage: false,
  hideOutcomesView: () => {},
}

OutcomeGroupHeader.propTypes = {
  title: PropTypes.string,
  description: PropTypes.string,
  minWidth: PropTypes.string,
  canManage: PropTypes.bool,
  onMenuHandler: PropTypes.func.isRequired,
  hideOutcomesView: PropTypes.func,
}

export default OutcomeGroupHeader
