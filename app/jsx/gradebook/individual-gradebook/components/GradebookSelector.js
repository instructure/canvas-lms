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

import {head, tail} from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!gradebook_individual_gradebook_gradebook_selector'

import CanvasSelect from '../../../shared/components/CanvasSelect'

const INDIVIDUAL_GRADEBOOK = 'IndividualGradebook'
const LEARNING_MASTERY = 'LearningMastery'

function isLearningMastery(state) {
  return state.value === LEARNING_MASTERY
}

class GradebookSelector extends React.Component {
  static propTypes = {
    courseUrl: PropTypes.string.isRequired,
    learningMasteryEnabled: PropTypes.bool.isRequired,
    navigate: PropTypes.func
  }

  static defaultProps = {
    navigate(url) {
      window.location = url
    }
  }

  constructor(props) {
    super(props)

    this.state = {value: INDIVIDUAL_GRADEBOOK}

    this.handleOnChange = this.handleOnChange.bind(this)
  }

  selectIndividualGradebook() {
    this.setState({value: INDIVIDUAL_GRADEBOOK}, () => {
      // hacky way to avoid needing to crack open Ember code
      document.querySelectorAll('ic-tab')[0].click()
    })
  }

  selectLearningMastery() {
    this.setState({value: LEARNING_MASTERY}, () => {
      // hacky way to avoid needing to crack open Ember code
      document.querySelectorAll('ic-tab')[1].click()
    })
  }

  selectGradebookHistory() {
    this.props.navigate(`${this.props.courseUrl}/gradebook/history`)
  }

  selectDefaultGradebook() {
    this.props.navigate(
      `${this.props.courseUrl}/gradebook/change_gradebook_version?version=default`
    )
  }

  handleOnChange(_event, value) {
    const valueFunctionMap = {
      [INDIVIDUAL_GRADEBOOK]: this.selectIndividualGradebook.bind(this),
      [LEARNING_MASTERY]: this.selectLearningMastery.bind(this),
      'default-gradebook': this.selectDefaultGradebook.bind(this),
      'gradebook-history': this.selectGradebookHistory.bind(this)
    }
    valueFunctionMap[value]()
  }

  renderOptions() {
    let modifiedVariant = 'IndividualGradebook'
    if (this.props.learningMasteryEnabled && isLearningMastery(this.state)) {
      modifiedVariant = `${modifiedVariant}LearningMastery`
    }
    const optionsForGradebook = {
      IndividualGradebook: [
        'IndividualGradebook',
        'LearningMastery',
        'DefaultGradebook',
        'GradebookHistory'
      ],
      IndividualGradebookLearningMastery: [
        'LearningMastery',
        'IndividualGradebook',
        'DefaultGradebook',
        'GradebookHistory'
      ]
    }
    const options = optionsForGradebook[modifiedVariant]
    return [
      this[`render${head(options)}Option`](true),
      ...tail(options).map(option => this[`render${option}Option`]())
    ]
  }

  renderIndividualGradebookOption(selected = false) {
    const label = selected ? I18n.t('Individual View') : I18n.t('Individual View…')
    return (
      <CanvasSelect.Option
        id={INDIVIDUAL_GRADEBOOK}
        key={INDIVIDUAL_GRADEBOOK}
        value={INDIVIDUAL_GRADEBOOK}
      >
        {label}
      </CanvasSelect.Option>
    )
  }

  renderLearningMasteryOption(selected = false) {
    if (!this.props.learningMasteryEnabled) return null
    const label = selected ? I18n.t('Learning Mastery') : I18n.t('Learning Mastery…')
    return (
      <CanvasSelect.Option id={LEARNING_MASTERY} value={LEARNING_MASTERY} key={LEARNING_MASTERY}>
        {label}
      </CanvasSelect.Option>
    )
  }

  renderDefaultGradebookOption() {
    const key = 'default-gradebook'
    return (
      <CanvasSelect.Option id={key} value={key} key={key}>
        {I18n.t('Gradebook…')}
      </CanvasSelect.Option>
    )
  }

  renderGradebookHistoryOption() {
    const key = 'gradebook-history'
    return (
      <CanvasSelect.Option id={key} value={key} key={key}>
        {I18n.t('Gradebook History…')}
      </CanvasSelect.Option>
    )
  }

  render() {
    return (
      <div style={{display: 'flex', alignItems: 'center'}}>
        <Text>{I18n.t('Gradebook')}</Text>
        &nbsp;
        <CanvasSelect
          onChange={this.handleOnChange}
          label={<ScreenReaderContent>{I18n.t('Gradebook')}</ScreenReaderContent>}
          value={this.state.value}
        >
          {this.renderOptions()}
        </CanvasSelect>
      </div>
    )
  }
}

export default GradebookSelector
