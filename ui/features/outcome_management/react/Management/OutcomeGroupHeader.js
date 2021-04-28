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

import React from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!OutcomeManagement'
import OutcomeKebabMenu from './OutcomeKebabMenu'
import OutcomeDescription from './OutcomeDescription'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'

const OutcomeGroupHeader = ({title, description, minWidth, onMenuHandler, canManage}) => (
  <View as="div">
    <Flex as="div" alignItems="start">
      <Flex.Item size={minWidth} shouldGrow>
        <div style={{padding: '0.21875rem 0'}}>
          <Heading level="h2">
            <div style={{overflowWrap: 'break-word'}}>
              {title
                ? I18n.t('%{title} Outcomes', {title: addZeroWidthSpace(title)})
                : I18n.t('Outcomes')}
            </div>
          </Heading>
        </div>
      </Flex.Item>
      {canManage && (
        <Flex.Item>
          <OutcomeKebabMenu
            canDestroy
            menuTitle={I18n.t('Outcome Group Menu')}
            onMenuHandler={onMenuHandler}
          />
        </Flex.Item>
      )}
    </Flex>
    <View as="div" padding="small 0 0">
      <OutcomeDescription description={description} />
    </View>
  </View>
)

OutcomeGroupHeader.defaultProps = {
  minWidth: 'auto',
  title: '',
  description: '',
  canManage: false
}

OutcomeGroupHeader.propTypes = {
  title: PropTypes.string,
  description: PropTypes.string,
  minWidth: PropTypes.string,
  canManage: PropTypes.bool,
  onMenuHandler: PropTypes.func.isRequired
}

export default OutcomeGroupHeader
