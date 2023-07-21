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

import Identicon from 'react-identicons'
import React from 'react'
import {string} from 'prop-types'

import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

const CURRENT_USER = 'current_user'

export const AnonymousAvatar = ({seedString, size, addFocus}) => {
  return (
    <View
      tabIndex={addFocus}
      display="inline-block"
      textAlign="center"
      borderRadius="circle"
      borderWidth="medium"
      width={size === 'medium' ? '50px' : '20px'}
      height={size === 'medium' ? '50px' : '20px'}
      data-testid="anonymous_avatar"
      background={seedString === CURRENT_USER ? 'primary-inverse' : undefined}
    >
      <Flex width="100%" height="100%" alignItems="center" justifyItems="center">
        <Flex.Item margin="xx-small 0 0 0">
          <Identicon
            string={seedString}
            size={size === 'medium' ? 30 : 10}
            fg={seedString === CURRENT_USER ? 'white' : undefined}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

AnonymousAvatar.propTypes = {
  seedString: string,
  addFocus: string,
  size: string,
}

AnonymousAvatar.defaultProps = {
  size: 'medium',
  addFocus: null,
}
