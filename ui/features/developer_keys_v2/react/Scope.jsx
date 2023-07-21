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
import PropTypes from 'prop-types'
import React from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'
import ScopesMethod from './ScopesMethod'

const I18n = useI18nScope('react_developer_keys')

const DeveloperKeyScope = props => {
  return (
    <View as="div" data-automation="developer-key-scope">
      <Flex alignItems="start" padding="small medium small none">
        <Flex.Item padding="none">
          <Checkbox
            label={
              <ScreenReaderContent>
                {props.checked ? I18n.t('Disable scope') : I18n.t('Enable scope')}
              </ScreenReaderContent>
            }
            value={props.scope.scope}
            onChange={props.onChange}
            checked={props.checked}
            inline={true}
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          {props.scope.scope}
        </Flex.Item>
        <Flex.Item>
          <ScopesMethod method={props.scope.verb} />
        </Flex.Item>
      </Flex>
    </View>
  )
}

DeveloperKeyScope.propTypes = {
  onChange: PropTypes.func.isRequired,
  checked: PropTypes.bool.isRequired,
  scope: PropTypes.shape({
    scope: PropTypes.string.isRequired,
    resource: PropTypes.string.isRequired,
    path: PropTypes.string,
    verb: PropTypes.string.isRequired,
  }).isRequired,
}

export default DeveloperKeyScope
