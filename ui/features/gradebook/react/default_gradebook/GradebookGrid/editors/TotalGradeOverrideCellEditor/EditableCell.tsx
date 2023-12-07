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

import React from 'react'
import {bool, func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {InstUISettingsProvider} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import {IconExpandStartLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

import GradeInput from '../GradeInput/GradeInput'
import {gradeEntry, gradeInfo} from '../GradeInput/PropTypes'
import CellEditorComponent from '../CellEditorComponent'
import InvalidGradeIndicator from '../InvalidGradeIndicator'
import useStore from '../../../stores'

const I18n = useI18nScope('gradebook')

const themeOverrides = {
  componentOverrides: {
    IconButton: {
      iconPadding: '0 3px',
      smallHeight: '23px',
    },
  },
}

export default class EditableCell extends CellEditorComponent {
  static propTypes = {
    gradeEntry: gradeEntry.isRequired,
    gradeInfo,
    gradeIsUpdating: bool.isRequired,
    onGradeUpdate: func.isRequired,
    pendingGradeInfo: gradeInfo,
    disabledByCustomStatus: bool,
  }

  static defaultProps = {
    gradeInfo: null,
    pendingGradeInfo: null,
  }

  componentDidMount() {
    if (!this.props.gradeIsUpdating) {
      this.gradeInput.focus()
    }
  }

  componentDidUpdate(prevProps) {
    const gradeFinishedUpdating = prevProps.gradeIsUpdating && !this.props.gradeIsUpdating

    if (gradeFinishedUpdating) {
      // the cell was reactivated while the grade was updating
      // set the focus on the input by default
      this.gradeInput.focus()
    }
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  applyValue() {
    this.props.onGradeUpdate(this.gradeInput.gradeInfo)
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  focus() {
    this.gradeInput.focus()
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  handleKeyDown(event) {
    const inputHandled = this.gradeInput.handleKeyDown(event)
    if (inputHandled != null) {
      return inputHandled
    }

    const indicatorHasFocus = this.invalidGradeIndicator === document.activeElement
    const inputHasFocus = this.contentContainer.contains(document.activeElement)
    const hasPreviousElement = inputHasFocus && this.invalidGradeIndicator

    // Tab
    if (event.which === 9) {
      if (!event.shiftKey && indicatorHasFocus) {
        return false // prevent Grid behavior
      } else if (event.shiftKey && hasPreviousElement) {
        return false // prevent Grid behavior
      }
    }

    return undefined
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  isValueChanged() {
    return this.gradeInput.hasGradeChanged()
  }

  render() {
    const gradeIsInvalid = this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid

    return (
      <InstUISettingsProvider theme={themeOverrides}>
        <div className={`Grid__GradeCell ${this.props.gradeEntry.enterGradesAs}`}>
          <div className="Grid__GradeCell__StartContainer">
            {gradeIsInvalid && (
              <InvalidGradeIndicator
                elementRef={ref => {
                  this.invalidGradeIndicator = ref
                }}
              />
            )}
          </div>

          <div
            className="Grid__GradeCell__Content"
            ref={ref => {
              this.contentContainer = ref
            }}
          >
            <GradeInput
              disabled={this.props.gradeIsUpdating || this.props.disabledByCustomStatus}
              gradeEntry={this.props.gradeEntry}
              gradeInfo={this.props.gradeInfo}
              pendingGradeInfo={this.props.pendingGradeInfo}
              ref={ref => {
                this.gradeInput = ref
              }}
            />
          </div>

          <View as="div" className="Grid__GradeCell__EndContainer">
            {this.props.customGradeStatusesEnabled && (
              <View as="div" className="Grid__GradeCell__Options">
                <IconButton
                  onClick={() => {
                    const {toggleFinalGradeOverrideTray} = useStore.getState()
                    toggleFinalGradeOverrideTray()
                    this.props.onTrayOpen()
                  }}
                  size="small"
                  renderIcon={IconExpandStartLine}
                  color="secondary"
                  screenReaderLabel={I18n.t('Open total grade override tray')}
                />
              </View>
            )}
          </View>
        </div>
      </InstUISettingsProvider>
    )
  }
}
