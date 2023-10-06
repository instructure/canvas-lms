// @ts-nocheck
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

import React, {Component} from 'react'
import {InstUISettingsProvider} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import {IconExpandStartLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import AssignmentGradeInput from '../AssignmentGradeInput/index'
import InvalidGradeIndicator from '../InvalidGradeIndicator'
import SimilarityIndicator from '../SimilarityIndicator'
import type {Submission} from '../../../../../../../api.d' // !!!! FIXME
import type {CamelizedAssignment, GradeEntryMode} from '@canvas/grading/grading.d'

const I18n = useI18nScope('gradebook')

const componentOverrides = {
  IconButton: {
    iconPadding: '0 3px',
    smallHeight: '23px',
  },
  TextInput: {
    smallHeight: '27px',
  },
}

type Props = {
  enterGradesAs: GradeEntryMode

  assignment: CamelizedAssignment

  editorOptions: {
    column: {
      assignmentId: string
    }
    grid: {}
    item: {
      id: string
    }
  }

  gradingScheme: [name: string, value: number][]

  onGradeSubmission: (submission: Submission, grade: string) => void

  onToggleSubmissionTrayOpen: (assignmentId: string, userId: string) => void

  pendingGradeInfo: {
    enteredAs: string
    excused: boolean
    grade: string
    score: number
    valid: boolean
  } | null

  submission: Submission

  submissionIsUpdating: boolean
}

export default class AssignmentRowCell extends Component<Props> {
  bindContainerRef: (ref: HTMLDivElement | null) => void

  contentContainer: HTMLDivElement | null = null

  bindStartContainerIndicatorRef: (ref: HTMLButtonElement | null) => void

  startContainerIndicator: HTMLButtonElement | null = null

  bindGradeInput: (ref: AssignmentGradeInput | null) => void

  gradeInput: AssignmentGradeInput | null = null

  bindToggleTrayButtonRef: (ref: Element | null) => void

  trayButton: Element | null = null

  submissionIsUpdating: boolean = false

  static defaultProps = {
    pendingGradeInfo: null,
  }

  constructor(props: Props) {
    super(props)

    this.bindContainerRef = ref => {
      this.contentContainer = ref
    }
    this.bindStartContainerIndicatorRef = ref => {
      this.startContainerIndicator = ref
    }
    this.bindGradeInput = ref => {
      this.gradeInput = ref
    }
    this.bindToggleTrayButtonRef = ref => {
      this.trayButton = ref
    }

    this.gradeSubmission = this.gradeSubmission.bind(this)
  }

  componentDidMount() {
    if (
      !this.props.submissionIsUpdating &&
      this.trayButton !== document.activeElement &&
      this.gradeInput instanceof AssignmentGradeInput
    ) {
      this.gradeInput.focus()
    }
  }

  componentDidUpdate(prevProps: Props) {
    const submissionFinishedUpdating =
      prevProps.submissionIsUpdating && !this.props.submissionIsUpdating

    if (
      submissionFinishedUpdating &&
      this.trayButton !== document.activeElement &&
      this.gradeInput instanceof AssignmentGradeInput
    ) {
      // the cell was reactivated while the grade was updating
      // set the focus on the input by default
      this.gradeInput.focus()
    }
  }

  handleKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
    const indicatorHasFocus = this.startContainerIndicator === document.activeElement
    const inputHasFocus = this.contentContainer?.contains(document.activeElement)
    const trayButtonHasFocus = this.trayButton === document.activeElement

    if (this.gradeInput) {
      const inputHandled = this.gradeInput.handleKeyDown(event)
      if (inputHandled != null) {
        return inputHandled
      }
    }

    const hasPreviousElement = trayButtonHasFocus || (inputHasFocus && this.startContainerIndicator)
    const hasNextElement = inputHasFocus || indicatorHasFocus

    // Tab
    if (event.which === 9) {
      if (!event.shiftKey && hasNextElement) {
        return false // prevent Grid behavior
      } else if (event.shiftKey && hasPreviousElement) {
        return false // prevent Grid behavior
      }
    }

    // Enter
    if (event.which === 13 && trayButtonHasFocus) {
      // browser will activate the tray button
      return false // prevent Grid behavior
    }

    return undefined
  }

  handleToggleTrayButtonClick = () => {
    const options = this.props.editorOptions
    this.props.onToggleSubmissionTrayOpen(options.item.id, options.column.assignmentId)
  }

  focus() {
    if (this.gradeInput instanceof AssignmentGradeInput) {
      this.gradeInput.focus()
    }
  }

  gradeSubmission() {
    if (this.gradeInput instanceof AssignmentGradeInput) {
      this.props.onGradeSubmission(this.props.submission, this.gradeInput.gradeInfo)
    }
  }

  isValueChanged(): boolean {
    return this.gradeInput?.hasGradeChanged() || false
  }

  render() {
    let pointsPossible: null | string = null
    if (this.props.enterGradesAs === 'points' && this.props.assignment.pointsPossible) {
      pointsPossible = `/${I18n.n(this.props.assignment.pointsPossible)}`
    }

    const gradeIsInvalid = this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid

    const {similarityInfo} = this.props.submission
    const showSimilarityIcon = !gradeIsInvalid && similarityInfo != null

    return (
      <InstUISettingsProvider theme={{componentOverrides}}>
        <div className={`Grid__GradeCell ${this.props.enterGradesAs}`}>
          <div className="Grid__GradeCell__StartContainer">
            {gradeIsInvalid && (
              <InvalidGradeIndicator elementRef={this.bindStartContainerIndicatorRef} />
            )}
            {showSimilarityIcon && similarityInfo && (
              <SimilarityIndicator
                elementRef={this.bindStartContainerIndicatorRef}
                similarityInfo={similarityInfo}
              />
            )}
          </div>

          <div className="Grid__GradeCell__Content" ref={this.bindContainerRef}>
            <AssignmentGradeInput
              assignment={this.props.assignment}
              enterGradesAs={this.props.enterGradesAs}
              disabled={this.props.submissionIsUpdating}
              gradingScheme={this.props.gradingScheme}
              pendingGradeInfo={this.props.pendingGradeInfo}
              ref={this.bindGradeInput}
              submission={this.props.submission}
            />
          </div>

          <div className="Grid__GradeCell__EndContainer">
            {this.props.enterGradesAs === 'points' && (
              <span className="Grid__GradeCell__EndText">
                {pointsPossible && <Text size="small">{pointsPossible}</Text>}
              </span>
            )}

            <div className="Grid__GradeCell__Options">
              <IconButton
                elementRef={this.bindToggleTrayButtonRef}
                onClick={this.handleToggleTrayButtonClick}
                size="small"
                renderIcon={IconExpandStartLine}
                color="secondary"
                screenReaderLabel={I18n.t('Open submission tray')}
              />
            </div>
          </div>
        </div>
      </InstUISettingsProvider>
    )
  }
}
