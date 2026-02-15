/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import type {Dispatch} from 'redux'

import BlueprintModal from '@canvas/blueprint-courses/react/components/BlueprintModal'
import MasterChildStack from './MasterChildStack'
import {ConnectedChildChangeLog as ChildChangeLog} from './ChildChangeLog'

import actions from '@canvas/blueprint-courses/react/actions'
import type {
  BlueprintState,
  Term,
  CourseInfo,
  RouteParams,
} from '@canvas/blueprint-courses/react/types'

const I18n = createI18nScope('blueprint_coursesChildContent')

export interface ChildContentProps {
  realRef?: (ref: ChildContent | null) => void
  routeTo: (path: string) => void
  isChangeLogOpen: boolean
  selectChangeLog: (params: RouteParams | null) => void
  terms: Term[]
  childCourse: CourseInfo
  masterCourse: CourseInfo
}

export default class ChildContent extends Component<ChildContentProps> {
  static defaultProps = {
    realRef: () => {},
  }

  componentDidMount(): void {
    this.props.realRef?.(this)
  }

  componentDidUpdate(prevProps: ChildContentProps): void {
    // it's awkward to reach outside the component to give the Modal's trigger
    // focus when it closes but the way our opening is decoupled from the button
    // through 'router' makes that impossible
    if (prevProps.isChangeLogOpen && !this.props.isChangeLogOpen) {
      const infoButton = document.querySelector<HTMLElement>('.blueprint_information_button')
      if (infoButton) infoButton.focus()
    }
  }

  clearRoutes = (): void => {
    this.props.routeTo('#!/blueprint')
  }

  showChangeLog(params: RouteParams): void {
    this.props.selectChangeLog(params)
  }

  hideChangeLog(): void {
    this.props.selectChangeLog(null)
  }

  render(): React.JSX.Element {
    const {terms, childCourse, masterCourse, isChangeLogOpen} = this.props
    const childTerm = terms.find(term => term.id === childCourse.enrollment_term_id)
    const childTermName = childTerm ? childTerm.name : ''

    return (
      <div className="bcc__wrapper">
        <BlueprintModal
          wide={true}
          title={I18n.t('Blueprint Course Information: %{term} - %{course}', {
            term: childTermName,
            course: childCourse.name,
          })}
          isOpen={isChangeLogOpen}
          onCancel={this.clearRoutes}
        >
          <div>
            <div style={{display: 'flex', justifyContent: 'space-between'}}>
              <MasterChildStack terms={terms} child={childCourse} master={masterCourse} />
              <div style={{width: '870px'}}>
                <ChildChangeLog />
              </div>
            </div>
          </div>
        </BlueprintModal>
      </div>
    )
  }
}

const connectState = (state: BlueprintState) => ({
  isChangeLogOpen: !!state.selectedChangeLog,
  childCourse: state.course,
  masterCourse: state.masterCourse,
  terms: state.terms,
})

const connectActions = (dispatch: Dispatch) => bindActionCreators(actions, dispatch)

export const ConnectedChildContent = connect(connectState, connectActions)(ChildContent)
