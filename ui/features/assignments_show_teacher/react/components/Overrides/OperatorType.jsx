/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2')

// eslint-disable-next-line react/prefer-stateless-function
export default class OperatorType extends React.Component {
  static propTypes = {
    value: string.isRequired,
  }

  static defaultProps = {
    value: 'or',
  }

  render() {
    const display = this.props.value === 'or' ? I18n.t('Or') : I18n.t('And')
    return (
      <View display="inline-block" width="100%">
        <Flex margin="0 x-small 0 0" justifyItems="center">
          <Flex.Item borderWidth="small" borderRadius="medium" padding="x-small x-small">
            <Text>{display}</Text>
          </Flex.Item>
        </Flex>
      </View>
    )
  }
}
