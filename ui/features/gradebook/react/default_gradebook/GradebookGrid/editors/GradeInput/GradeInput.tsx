// @ts-nocheck
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

import React, {PureComponent} from 'react'
import {bool} from 'prop-types'
import {InstUISettingsProvider} from '@instructure/emotion'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {useScope as useI18nScope} from '@canvas/i18n'

import {gradeEntry, gradeInfo} from './PropTypes'
import TextGradeInput from './TextGradeInput'

const I18n = useI18nScope('gradebook')

const CLASSNAME_FOR_ENTER_GRADES_AS = {
  gradingScheme: 'Grid__GradeCell__GradingSchemeInput',
  percent: 'Grid__GradeCell__PercentInput',
}

const componentOverrides = {
  [Button.componentId]: {
    iconPadding: '0 3px',
    smallHeight: '23px',
  },

  [TextInput.componentId]: {
    smallHeight: '27px',
  },
}

export default class GradeInput extends PureComponent {
  static propTypes = {
    disabled: bool,
    gradeEntry: gradeEntry.isRequired,
    gradeInfo: gradeInfo.isRequired,
    pendingGradeInfo: gradeInfo,
  }

  static defaultProps = {
    disabled: false,
    pendingGradeInfo: null,
  }

  constructor(props) {
    super(props)

    this.handleKeyDown = this.handleKeyDown.bind(this)
  }

  /*
   * GradeInfo for the grade currently represented in the input.
   */
  get gradeInfo() {
    return this.gradeInput.gradeInfo
  }

  /*
   * Set focus on the default element of the grade input.
   */
  focus() {
    this.gradeInput.focus()
  }

  /*
   * Delegate a SlickGrid keyDown event to the input.
   */
  handleKeyDown(event) {
    return this.gradeInput.handleKeyDown(event)
  }

  /*
   * Returns true if the grade entered differs from the original grade.
   */
  hasGradeChanged() {
    return this.props.gradeEntry.hasGradeChanged(
      this.props.gradeInfo,
      this.gradeInput.gradeInfo,
      this.props.pendingGradeInfo
    )
  }

  render() {
    const className = CLASSNAME_FOR_ENTER_GRADES_AS[this.props.gradeEntry.enterGradesAs]

    const messages = []
    if (this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid) {
      messages.push({type: 'error', text: I18n.t('This grade is invalid')})
    }

    return (
      <div className={className}>
        <InstUISettingsProvider theme={{componentOverrides}}>
          <TextGradeInput
            {...this.props}
            label={<ScreenReaderContent>{I18n.t('Grade')}</ScreenReaderContent>}
            messages={messages}
            ref={ref => {
              this.gradeInput = ref
            }}
          />
        </InstUISettingsProvider>
      </div>
    )
  }
}
