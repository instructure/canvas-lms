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

import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import React from 'react'
import I18n from 'i18n!assignments'
import FinalGraderSelectMenu from './FinalGraderSelectMenu'
import GraderCommentVisibilityCheckbox from './GraderCommentVisibilityCheckbox'
import GraderCountNumberInput from './GraderCountNumberInput'
import GraderNamesVisibleToFinalGraderCheckbox from './GraderNamesVisibleToFinalGraderCheckbox'
import ModeratedGradingCheckbox from './ModeratedGradingCheckbox'
import {direction} from '../shared/helpers/rtlHelper'

export default class ModeratedGradingFormFieldGroup extends React.Component {
  static propTypes = {
    availableModerators: arrayOf(shape({name: string.isRequired, id: string.isRequired})).isRequired,
    currentGraderCount: number,
    finalGraderID: string,
    graderCommentsVisibleToGraders: bool.isRequired,
    graderNamesVisibleToFinalGrader: bool.isRequired,
    gradedSubmissionsExist: bool.isRequired,
    isGroupAssignment: bool.isRequired,
    isPeerReviewAssignment: bool.isRequired,
    locale: string.isRequired,
    maxGraderCount: number.isRequired,
    moderatedGradingEnabled: bool.isRequired,
    onGraderCommentsVisibleToGradersChange: func.isRequired,
    onModeratedGradingChange: func.isRequired
  }

  static defaultProps = {
    currentGraderCount: null,
    finalGraderID: null
  }

  constructor(props) {
    super(props)
    this.handleModeratedGradingChange = this.handleModeratedGradingChange.bind(this)
    this.state = {
      moderatedGradingChecked: props.moderatedGradingEnabled
    }
  }

  componentDidUpdate(_, prevState) {
    if (this.state.moderatedGradingChecked !== prevState.moderatedGradingChecked) {
      this.props.onModeratedGradingChange(this.state.moderatedGradingChecked)
    }
  }

  handleModeratedGradingChange(moderatedGradingChecked) {
    this.setState({moderatedGradingChecked})
  }

  render() {
    return (
      <fieldset>
        <div className={`form-column-${direction('left')}`}>{I18n.t('Moderated Grading')}</div>
        <div className="ModeratedGrading__Container">
          <div className="border border-trbl border-round">
            <ModeratedGradingCheckbox
              checked={this.state.moderatedGradingChecked}
              gradedSubmissionsExist={this.props.gradedSubmissionsExist}
              isGroupAssignment={this.props.isGroupAssignment}
              isPeerReviewAssignment={this.props.isPeerReviewAssignment}
              onChange={this.handleModeratedGradingChange}
            />

            {this.state.moderatedGradingChecked && (
              <div className="ModeratedGrading__Content">
                <GraderCountNumberInput
                  currentGraderCount={this.props.currentGraderCount}
                  maxGraderCount={this.props.maxGraderCount}
                  locale={this.props.locale}
                />

                <GraderCommentVisibilityCheckbox
                  checked={this.props.graderCommentsVisibleToGraders}
                  onChange={this.props.onGraderCommentsVisibleToGradersChange}
                />

                <FinalGraderSelectMenu
                  availableModerators={this.props.availableModerators}
                  finalGraderID={this.props.finalGraderID}
                />

                <GraderNamesVisibleToFinalGraderCheckbox
                  checked={this.props.graderNamesVisibleToFinalGrader}
                />
              </div>
            )}
          </div>
        </div>
      </fieldset>
    )
  }
}
