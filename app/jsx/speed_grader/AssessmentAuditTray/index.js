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

import React, {Component} from 'react'
import {func} from 'prop-types'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Tray from '@instructure/ui-overlays/lib/components/Tray'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!speed_grader'

import AssessmentSummary from './components/AssessmentSummary'

export default class AssessmentAuditTray extends Component {
  static propTypes = {
    onEntered: func,
    onExited: func
  }

  static defaultProps = {
    onEntered() {},
    onExited() {}
  }

  constructor(props) {
    super(props)

    this.dismiss = this.dismiss.bind(this)
    this.show = this.show.bind(this)

    this.state = {
      open: false
    }
  }

  dismiss() {
    this.setState({open: false})
  }

  show(context) {
    this.setState({
      ...context,
      open: true
    })
  }

  render() {
    if (!this.state.assignment) {
      return null
    }

    const {onEntered, onExited} = this.props

    return (
      <Tray
        label={I18n.t('Assessment audit tray')}
        onEntered={onEntered}
        onExited={onExited}
        open={this.state.open}
        placement="end"
      >
        <View as="div" padding="small">
          <Flex as="div" margin="0 0 medium 0">
            <FlexItem>
              <CloseButton onClick={this.dismiss}>{I18n.t('Close')}</CloseButton>
            </FlexItem>

            <FlexItem margin="0 0 0 small">
              <Heading as="h1" level="h3">
                {I18n.t('Assessment audit')}
              </Heading>
            </FlexItem>
          </Flex>

          <View as="div" margin="small">
            <AssessmentSummary
              assignment={this.state.assignment}
              submission={this.state.submission}
            />
          </View>
        </View>
      </Tray>
    )
  }
}
