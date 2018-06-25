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
import {arrayOf, bool, func, number, objectOf, shape, string} from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import RadioInputGroup from '@instructure/ui-forms/lib/components/RadioInputGroup'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!gradebook'

const NEW_CUSTOM_GRADE = 'custom'

export default class SpeedGraderProvisionalGradeSelector extends React.Component {
  static propTypes = {
    gradingType: string.isRequired,
    onGradeSelected: func.isRequired,
    pointsPossible: number,
    provisionalGraderDisplayNames: objectOf(string).isRequired,
    provisionalGrades: arrayOf(shape({
      anonymous_grader_id: string,
      grade: string.isRequired,
      provisional_grade_id: string.isRequired,
      readonly: bool,
      scorer_id: string,
      selected: bool
    })).isRequired
  }

  static defaultProps = {
    pointsPossible: 0
  }

  constructor(props) {
    super(props)
    this.state = {detailsVisible: false}

    this.onDetailsToggled = this.onDetailsToggled.bind(this)
    this.handleGradeSelected = this.handleGradeSelected.bind(this)
  }

  onDetailsToggled() {
    this.setState(prevState => ({detailsVisible: !prevState.detailsVisible}))
  }

  handleGradeSelected(_event, value) {
    // If this is the current user's grade, we'll need to submit the changes
    // to the server
    if (value === NEW_CUSTOM_GRADE) {
      this.props.onGradeSelected({isNewGrade: true})
    } else {
      const selectedGrade = this.props.provisionalGrades.find(
        grade => grade.provisional_grade_id === value
      )
      this.props.onGradeSelected({selectedGrade})
    }
  }

  renderRadioInputLabel(grade) {
    const {pointsPossible} = this.props
    const graderName = this.props.provisionalGraderDisplayNames[grade.provisional_grade_id]

    // A provisional grade isn't *really* a submission object, but it has the
    // two fields ("score" and "grade") relevant to formatting.
    const formattedScore = GradeFormatHelper.formatSubmissionGrade(grade, {formatType: this.props.gradingType})

    return (
      <View>
        <Text size="small" weight="bold">{formattedScore}</Text>
        {this.props.gradingType === 'points' &&
          <Text size="small"> {I18n.t('out of %{pointsPossible}', {pointsPossible: I18n.n(pointsPossible)})}</Text>
        }

        <View padding="none small">
          <Text weight="light" size="small" fontStyle="italic">
            {graderName}
          </Text>
        </View>
      </View>
    )
  }

  renderDetailsContainer() {
    const {provisionalGrades} = this.props

    const selectedGrade = provisionalGrades.find(grade => grade.selected)
    const selectedValue = selectedGrade ? selectedGrade.provisional_grade_id : NEW_CUSTOM_GRADE

    // The "Custom" button (representing the moderator's own grade) is always
    // rendered at the top. It needs some slightly special handling since the
    // moderator might not have actually issued a provisional grade yet.
    const gradeIssuedByMe = provisionalGrades.find(grade => !grade.readonly)
    this.moderatorGradeId = gradeIssuedByMe
      ? gradeIssuedByMe.provisional_grade_id
      : NEW_CUSTOM_GRADE

    const gradesIssuedByOthers = provisionalGrades.filter(grade => grade.readonly)

    if (gradesIssuedByOthers.length > 0 && gradesIssuedByOthers[0].anonymous_grader_id) {
      gradesIssuedByOthers.sort((a, b) => a.anonymous_grader_id > b.anonymous_grader_id)
    } else {
      gradesIssuedByOthers.sort((a, b) => a.scorer_id > b.scorer_id)
    }

    return (
      <View as="div" id="grading_details" margin="small">
        <Heading as="h4" margin="small auto">
          <Text transform="uppercase" letterSpacing="expanded">
            {I18n.t('How Is the Grade Determined?')}
          </Text>
        </Heading>

        <RadioInputGroup
          value={selectedValue}
          description={<ScreenReaderContent>{I18n.t('Select a provisional grade')}</ScreenReaderContent>}
          name="selected_provisional_grade"
          onChange={this.handleGradeSelected}
          size="small"
        >
          <RadioInput value={this.moderatorGradeId} label={<Text size="small">{I18n.t('Custom')}</Text>} />

          {gradesIssuedByOthers.map(grade => (
            <RadioInput
              key={grade.provisional_grade_id}
              value={grade.provisional_grade_id}
              label={this.renderRadioInputLabel(grade)}
            />
          ))}
        </RadioInputGroup>
      </View>
    )
  }

  render() {
    const {detailsVisible} = this.state

    return (
      <View as="div" id="grading_details_container">
        <Button margin="0" onClick={this.onDetailsToggled} size="small" variant="link">
          {detailsVisible ? I18n.t('Hide Details') : I18n.t('Show Details')}
        </Button>

        {detailsVisible && this.renderDetailsContainer()}
      </View>
    )
  }
}
