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
import {bool, func, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import EditableRichText from './Editables/EditableRichText'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2')

const descriptionPlaceholder = I18n.t('Description')

export default class AssignmentDescription extends React.Component {
  static propTypes = {
    text: string,
    onChange: func.isRequired,
    readOnly: bool,
  }

  static defaultPropTypes = {
    readOnly: false,
  }

  constructor(props) {
    super(props)

    this.state = {
      mode: 'view',
    }
  }

  handleChange = text => {
    this.props.onChange(text || null)
  }

  handleChangeMode = mode => {
    this.setState({mode})
  }

  render() {
    return (
      <View as="div" margin="0 0 small" data-testid="AssignmentDescription">
        <ToggleDetails
          defaultExpanded={true}
          summary={
            <>
              <Text>{I18n.t('Description')}</Text>
            </>
          }
        >
          <EditableRichText
            mode={this.state.mode}
            value={this.props.text || ''}
            placeholder={descriptionPlaceholder}
            onChange={this.handleChange}
            onChangeMode={this.handleChangeMode}
            label={I18n.t('Description')}
            readOnly={this.props.readOnly}
          />
        </ToggleDetails>
      </View>
    )
  }
}
