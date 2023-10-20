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
import {func, instanceOf} from 'prop-types'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Tray} from '@instructure/ui-tray'

import {useScope as useI18nScope} from '@canvas/i18n'

import AssessmentSummary from './components/AssessmentSummary'
import AuditTrail from './components/AuditTrail/index'
import Api from './Api'
import buildAuditTrail from './buildAuditTrail'

const I18n = useI18nScope('speed_grader')

export default class AssessmentAuditTray extends Component {
  static propTypes = {
    api: instanceOf(Api),
    onEntered: func,
    onExited: func,
  }

  static defaultProps = {
    api: new Api(),
    onEntered() {},
    onExited() {},
  }

  constructor(props) {
    super(props)

    this.state = {
      auditEventsLoaded: false,
      auditTrail: buildAuditTrail({}),
      open: false,
    }
  }

  dismiss = () => {
    this.setState({open: false})
  }

  show = context => {
    this.setState({
      ...context,
      auditEventsLoaded: false,
      auditTrail: buildAuditTrail({}),
      open: true,
    })

    const {assignment, courseId, submission} = context

    /* eslint-disable promise/catch-or-return */
    this.props.api
      .loadAssessmentAuditTrail(courseId, assignment.id, submission.id)
      .then(auditData => {
        if (this.state.open && this.state.submission.id === submission.id) {
          this.setState({
            auditEventsLoaded: true,
            auditTrail: buildAuditTrail(auditData),
          })
        }
      })
    /* eslint-enable promise/catch-or-return */
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
            <Flex.Item>
              <CloseButton onClick={this.dismiss} screenReaderLabel={I18n.t('Close')} />
            </Flex.Item>

            <Flex.Item margin="0 0 0 small">
              <Heading as="h2" level="h3">
                {I18n.t('Assessment audit')}
              </Heading>
            </Flex.Item>
          </Flex>

          {this.state.auditEventsLoaded ? (
            <>
              <View as="div" margin="small">
                <AssessmentSummary
                  anonymityDate={this.state.auditTrail.anonymityDate}
                  assignment={this.state.assignment}
                  finalGradeDate={this.state.auditTrail.finalGradeDate}
                  overallAnonymity={this.state.auditTrail.overallAnonymity}
                  submission={this.state.submission}
                />
              </View>

              <View as="div" margin="small">
                <AuditTrail auditTrail={this.state.auditTrail} />
              </View>
            </>
          ) : (
            <Spinner renderTitle={I18n.t('Loading assessment audit trail')} />
          )}
        </View>
      </Tray>
    )
  }
}
