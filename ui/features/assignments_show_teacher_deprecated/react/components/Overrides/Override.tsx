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
import {bool, func, number} from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {OverrideShape} from '../../assignmentData'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import OverrideSummary from './OverrideSummary'
import OverrideDetail from './OverrideDetail'

const I18n = createI18nScope('assignments_2')

export default class Override extends React.Component {
  static propTypes = {
    override: OverrideShape.isRequired,
    onChangeOverride: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    index: number.isRequired, // offset of this override in the assignment
    readOnly: bool,
  }

  static defaultProps = {
    readOnly: false,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    this.state = {
      expanded: false,
    }
  }

  // @ts-expect-error
  handleChangeOverride = (path, value) => {
    // @ts-expect-error
    return this.props.onChangeOverride(this.props.index, path, value)
  }

  // @ts-expect-error
  handleValidate = (path, value) => {
    // @ts-expect-error
    return this.props.onValidate(this.props.index, path, value)
  }

  // @ts-expect-error
  invalidMessage = path => {
    // @ts-expect-error
    return this.props.invalidMessage(this.props.index, path)
  }

  // @ts-expect-error
  handleToggle = (_event, expanded) => {
    this.setState({expanded})
  }

  render() {
    return (
      <View as="div" margin="0 0 small 0" data-testid="Override">
        <ToggleGroup
          // @ts-expect-error
          expanded={this.state.expanded}
          onToggle={this.handleToggle}
          toggleLabel={
            // @ts-expect-error
            this.state.expanded ? I18n.t('Click to hide details') : I18n.t('Click to show details')
          }
          // @ts-expect-error
          summary={<OverrideSummary override={this.props.override} />}
          // @ts-expect-error
          background="default"
        >
          <OverrideDetail
            // @ts-expect-error
            override={this.props.override}
            onChangeOverride={this.handleChangeOverride}
            onValidate={this.handleValidate}
            invalidMessage={this.invalidMessage}
            // @ts-expect-error
            readOnly={this.props.readOnly}
          />
        </ToggleGroup>
      </View>
    )
  }
}
