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
import {useScope as createI18nScope} from '@canvas/i18n'
import {InstUISettingsProvider} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import {IconExpandStartLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

import GradeInput from '../GradeInput/GradeInput'
import {gradeEntry, gradeInfo} from '../GradeInput/PropTypes'
import CellEditorComponent from '../CellEditorComponent'
import InvalidGradeIndicator from '../InvalidGradeIndicator'
import useStore from '../../../stores'

const I18n = createI18nScope('gradebook')

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
    // @ts-expect-error
    if (!this.props.gradeIsUpdating) {
      // @ts-expect-error
      this.gradeInput.focus()
    }
  }

  // @ts-expect-error
  componentDidUpdate(prevProps) {
    // @ts-expect-error
    const gradeFinishedUpdating = prevProps.gradeIsUpdating && !this.props.gradeIsUpdating

    if (gradeFinishedUpdating) {
      // the cell was reactivated while the grade was updating
      // set the focus on the input by default
      // @ts-expect-error
      this.gradeInput.focus()
    }
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  applyValue() {
    // @ts-expect-error
    this.props.onGradeUpdate(this.gradeInput.gradeInfo)
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  focus() {
    // @ts-expect-error
    this.gradeInput.focus()
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  // @ts-expect-error
  handleKeyDown(event) {
    // @ts-expect-error
    const inputHandled = this.gradeInput.handleKeyDown(event)
    if (inputHandled != null) {
      return inputHandled
    }

    // @ts-expect-error
    const indicatorHasFocus = this.invalidGradeIndicator === document.activeElement
    // @ts-expect-error
    const inputHasFocus = this.contentContainer.contains(document.activeElement)
    // @ts-expect-error
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
    // @ts-expect-error
    return this.gradeInput.hasGradeChanged()
  }

  render() {
    // @ts-expect-error
    const gradeIsInvalid = this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid

    return (
      <InstUISettingsProvider theme={themeOverrides}>
        {/* @ts-expect-error */}
        <div className={`Grid__GradeCell ${this.props.gradeEntry.enterGradesAs}`}>
          <div className="Grid__GradeCell__StartContainer">
            {gradeIsInvalid && (
              <InvalidGradeIndicator
                elementRef={ref => {
                  // @ts-expect-error
                  this.invalidGradeIndicator = ref
                }}
              />
            )}
          </div>

          <div
            className="Grid__GradeCell__Content"
            ref={ref => {
              // @ts-expect-error
              this.contentContainer = ref
            }}
          >
            <GradeInput
              // @ts-expect-error
              disabled={this.props.gradeIsUpdating || this.props.disabledByCustomStatus}
              // @ts-expect-error
              gradeEntry={this.props.gradeEntry}
              // @ts-expect-error
              gradeInfo={this.props.gradeInfo}
              // @ts-expect-error
              pendingGradeInfo={this.props.pendingGradeInfo}
              ref={ref => {
                // @ts-expect-error
                this.gradeInput = ref
              }}
            />
          </div>

          <View as="div" className="Grid__GradeCell__EndContainer">
            {/* @ts-expect-error */}
            {this.props.customGradeStatusesEnabled && (
              <View as="div" className="Grid__GradeCell__Options">
                <IconButton
                  onClick={() => {
                    const {toggleFinalGradeOverrideTray} = useStore.getState()
                    toggleFinalGradeOverrideTray()
                    // @ts-expect-error
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
