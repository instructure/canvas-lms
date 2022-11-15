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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'

const I18n = useI18nScope('course_paces_blueprint_lock')

interface PassedProps {
  readonly newPace: boolean
  readonly contextIsCoursePace: boolean
  readonly bannerSelector: string
  setIsBlueprintLocked: (arg) => void
}

export class BlueprintLock extends React.Component<PassedProps> {
  private lockManager

  private isLocked

  private isChild

  private tooltipMessage

  constructor(props: PassedProps) {
    super(props)
    this.lockManager = new LockManager()
    this.tooltipMessage = I18n.t('Blueprint locking is only available for published paces')
  }

  componentDidMount() {
    this.lockManager.init({
      itemType: 'course_pace',
      page: 'show',
      bannerSelector: this.props.bannerSelector,
    })
    this.isLocked = this.lockManager.state.isChildContent && this.lockManager.state.isLocked
    this.isChild = this.lockManager.state.isChildContent
    this.props.setIsBlueprintLocked(this.isLocked)
  }

  componentDidUpdate() {
    this.props.setIsBlueprintLocked(this.isLocked)
    this.tooltipMessage = this.props.contextIsCoursePace
      ? I18n.t('Blueprint locking is only available for published paces')
      : I18n.t('Blueprint locking is only available for the course-level pace')
  }

  render() {
    const disabledLock = (this.props.newPace || !this.props.contextIsCoursePace) && !this.isChild
    const disabledStyle = {pointerEvents: 'none', opacity: '0.5'}

    if (this.lockManager.shouldInit()) {
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
    return null
  }
}

export default BlueprintLock
