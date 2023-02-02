// @ts-nocheck
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

import React from 'react'
import {connect} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'
import {actions} from '../../actions/ui'
import {CoursePace, StoreState} from '../../types'
import {getCoursePace} from '../../reducers/course_paces'

const I18n = useI18nScope('course_paces_blueprint_lock')

interface PassedProps {
  readonly newPace: boolean
  readonly bannerSelector: string
}

interface DispatchProps {
  readonly setBlueprintLocked: typeof actions.setBlueprintLocked
}

interface StoreProps {
  readonly coursePace: CoursePace
}

export class BlueprintLock extends React.Component<PassedProps & StoreProps & DispatchProps> {
  private lockManager

  private isLocked

  private isChild

  private tooltipMessage

  private isCourseLevelPace

  private useRedesign

  constructor(props: PassedProps & StoreProps & DispatchProps) {
    super(props)
    this.lockManager = new LockManager()
    this.tooltipMessage = I18n.t('Blueprint locking is only available for published paces')
    this.useRedesign = window.ENV.FEATURES.course_paces_redesign
  }

  componentDidMount() {
    this.isCourseLevelPace = this.props.coursePace.context_type === 'Course'

    if (!this.lockManager.shouldInit() || (!this.isCourseLevelPace && this.useRedesign)) {
      this.props.setBlueprintLocked(false)
      return null
    }

    this.lockManager.init({
      itemType: 'course_pace',
      page: 'show',
      bannerSelector: this.props.bannerSelector,
      lockCallback: locked => {
        this.props.setBlueprintLocked(
          locked && this.isCourseLevelPace && this.lockManager.state.isChildContent
        )
        window.ENV.MASTER_COURSE_DATA.restricted_by_master_course = locked
      },
    })

    this.props.setBlueprintLocked(
      this.lockManager.state.isChildContent && this.lockManager.state.isLocked
    )
    this.isLocked = this.lockManager.state.isChildContent && this.lockManager.state.isLocked
    this.isChild = this.lockManager.state.isChildContent
  }

  componentDidUpdate() {
    this.lockManager.changeItemId(this.props.coursePace.id)
    this.isCourseLevelPace = this.props.coursePace.context_type === 'Course'
    this.tooltipMessage = this.isCourseLevelPace
      ? I18n.t('Blueprint locking is only available for published paces')
      : I18n.t('Blueprint locking is only available for the course-level pace')
  }

  render() {
    if (!this.lockManager.shouldInit() || (!this.isCourseLevelPace && this.useRedesign)) return null

    const disabledLock = (this.props.newPace || this.isCourseLevelPace === false) && !this.isChild
    const disabledStyle = {pointerEvents: 'none', opacity: '0.5'}

    return (
      <div style={{display: 'inline-block', marginLeft: '0.75rem'}}>
        <Tooltip
          placement="top"
          color="primary"
          renderTip={this.tooltipMessage}
          on={!disabledLock || this.isChild ? [] : ['hover', 'focus']}
        >
          <div className="blueprint-label" style={disabledLock ? disabledStyle : {}} />
          <ScreenReaderContent>{this.tooltipMessage}</ScreenReaderContent>
        </Tooltip>
      </div>
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    coursePace: getCoursePace(state),
  }
}

export default connect(mapStateToProps, {
  setBlueprintLocked: actions.setBlueprintLocked,
})(BlueprintLock)
