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

import React, {PureComponent} from 'react'
import {Button} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {WEEKLY_PLANNER_ACTIVE_BTN_ID} from '../WeeklyPlannerHeader'

const I18n = useI18nScope('planner')

export const WEEKLY_PLANNER_JUMP_TO_NAV_BUTTON = 'jump-to-weekly-nav-button'

export default class JumpToHeaderButton extends PureComponent {
  buttonRef = null

  state = {focused: false}

  setFocused = focused => () => {
    this.setState({focused}, () => this.buttonRef.scrollIntoView(false))
  }

  focusHeader = () => {
    document.getElementById(WEEKLY_PLANNER_ACTIVE_BTN_ID)?.focus()
  }

  render = () => (
    <div
      style={{
        display: 'flex',
        justifyContent: 'flex-end',
        opacity: this.state.focused ? '1' : '0',
        position: this.state.focused ? 'static' : 'absolute',
      }}
    >
      <Button
        id={WEEKLY_PLANNER_JUMP_TO_NAV_BUTTON}
        data-testid={WEEKLY_PLANNER_JUMP_TO_NAV_BUTTON}
        onClick={this.focusHeader}
        onBlur={this.setFocused(false)}
        onFocus={this.setFocused(true)}
        elementRef={e => {
          this.buttonRef = e
        }}
      >
        {I18n.t('Jump to navigation toolbar')}
      </Button>
    </div>
  )
}
