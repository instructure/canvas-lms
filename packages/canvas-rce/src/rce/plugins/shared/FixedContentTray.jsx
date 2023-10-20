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

import React from 'react'
import PropTypes from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {getTrayHeight} from './trayUtils'

// Need these styles for drawing over <ColorInput /> popup.
const topElementStyles = {zIndex: 10000}

function renderJoinedItem(bodyAs, renderBody, renderFooter) {
  return (
    <Flex.Item height="0" shouldGrow={true}>
      <Flex as={bodyAs} direction="column" margin="0" height="100%">
        <Flex.Item as="div" overflowX="auto" height="0" shouldGrow={true}>
          {renderBody()}
        </Flex.Item>
        <footer style={topElementStyles}>
          <View as="div" borderWidth="small none none none">
            {renderFooter()}
          </View>
        </footer>
      </Flex>
    </Flex.Item>
  )
}

export const FixedContentTray = ({
  title,
  isOpen,
  onDismiss,
  onUnmount,
  mountNode,
  renderHeader,
  renderBody,
  renderFooter,
  bodyAs,
  shouldJoinBodyAndFooter,
}) => {
  return (
    <Tray
      data-mce-component={true}
      label={title}
      mountNode={mountNode}
      onDismiss={onDismiss}
      onExited={onUnmount}
      open={isOpen}
      placement="end"
      shouldCloseOnDocumentClick={true}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      size="regular"
    >
      <Flex direction="column" height={getTrayHeight()}>
        <header style={topElementStyles}>
          <View as="div" borderWidth="none none small none">
            {renderHeader()}
          </View>
        </header>
        {shouldJoinBodyAndFooter ? (
          renderJoinedItem(bodyAs, renderBody, renderFooter)
        ) : (
          <>
            <Flex.Item as={bodyAs} overflowX="auto" height="0" shouldGrow={true}>
              {renderBody()}
            </Flex.Item>
            <footer style={topElementStyles}>
              <View as="div" borderWidth="none none small none">
                {renderFooter()}
              </View>
            </footer>
          </>
        )}
      </Flex>
    </Tray>
  )
}

FixedContentTray.propTypes = {
  renderHeader: PropTypes.func.isRequired,
  renderBody: PropTypes.func.isRequired,
  renderFooter: PropTypes.func.isRequired,
  title: PropTypes.string,
  isOpen: PropTypes.bool,
  onDismiss: PropTypes.func,
  onUnmount: PropTypes.func,
  mountNode: PropTypes.oneOfType([PropTypes.func, PropTypes.element]),
  bodyAs: PropTypes.string,
  shouldJoinBodyAndFooter: PropTypes.bool,
}

FixedContentTray.defaultProps = {
  title: null,
  isOpen: false,
  onDismiss: () => {},
  onUnmount: () => {},
  bodyAs: 'div',
  shouldJoinBodyAndFooter: false,
}
