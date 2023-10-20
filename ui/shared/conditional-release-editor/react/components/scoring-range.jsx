/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {connect} from 'react-redux'
import {List} from 'immutable'

import ScoreLabel from './score-label'
import ScoreInput from './score-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import AssignmentSet from './assignment-set'
import * as actions from '../actions'
import {useScope as useI18nScope} from '@canvas/i18n'
import {transformScore, getScoringRangeSplitWarning} from '../score-helpers'

const I18n = useI18nScope('conditional_release')

const {object, func, bool} = PropTypes

const MAX_SETS = 3

class ScoringRange extends React.Component {
  static get propTypes() {
    return {
      triggerAssignment: object,
      range: object.isRequired,
      path: object.isRequired,
      assignments: object.isRequired,
      isTop: bool,
      isBottom: bool,
      onScoreChanged: func,
      onAddItems: func,

      // action props
      removeAssignment: func.isRequired,
      mergeAssignmentSets: func.isRequired,
      splitAssignmentSet: func.isRequired,
      moveAssignment: func.isRequired,
      setAriaAlert: func.isRequired,
      setGlobalWarning: func.isRequired,
    }
  }

  constructor() {
    super()

    this.titleRef = React.createRef()
    this.handleAddItems = this.handleAddItems.bind(this)
    this.removeAssignment = this.removeAssignment.bind(this)
    this.toggleSetCondition = this.toggleSetCondition.bind(this)
  }

  handleAddItems() {
    this.props.onAddItems(this.props.path.range)
  }

  renderScoreLabel(score, label, isUpperBound) {
    return (
      <ScoreLabel
        score={score}
        label={label}
        isUpperBound={isUpperBound}
        triggerAssignment={this.props.triggerAssignment}
      />
    )
  }

  renderUpperBound() {
    if (this.props.isTop) {
      return this.renderScoreLabel(this.props.range.get('upper_bound'), I18n.t('Top Bound'), true)
    } else {
      return null
    }
  }

  renderLowerBound() {
    if (this.props.isBottom) {
      return this.renderScoreLabel(
        this.props.range.get('lower_bound'),
        I18n.t('Lower Bound'),
        false
      )
    } else {
      return (
        <ScoreInput
          score={this.props.range.get('lower_bound')}
          label={I18n.t('Division cutoff %{cutoff_value}', {
            cutoff_value: this.props.path.range + 1,
          })}
          error={this.props.range.get('error')}
          onScoreChanged={this.props.onScoreChanged}
          triggerAssignment={this.props.triggerAssignment}
        />
      )
    }
  }

  toggleSetCondition(path, isAnd, isDisabled) {
    if (isAnd) {
      if (isDisabled) {
        // see clearing method in actors.js
        this.props.setGlobalWarning(getScoringRangeSplitWarning())
      } else {
        this.props.splitAssignmentSet({
          index: path.range,
          assignmentSetIndex: path.set,
          splitIndex: path.assignment + 1,
        })
        this.props.setAriaAlert(I18n.t('Sets are split, click to merge'))
      }
    } else {
      this.props.mergeAssignmentSets({index: path.range, leftSetIndex: path.set})
      this.props.setAriaAlert(I18n.t('Sets are merged, click to split'))
    }
  }

  removeAssignment(path, asg) {
    this.props.removeAssignment({path})
    this.props.setAriaAlert(
      I18n.t('Removed assignment %{assignment_name}', {assignment_name: asg.get('name')})
    )
    setTimeout(() => this.titleRef.current.focus(), 1)
  }

  renderAssignmentSets() {
    const path = this.props.path

    return this.props.range
      .get('assignment_sets', List())
      .map((set, i, sets) => {
        return (
          <AssignmentSet
            key={set.get('id') || i}
            path={path.push(i)}
            label={I18n.t('Assignment set %{set_index}', {set_index: i + 1})}
            setAssignments={set.get('assignment_set_associations', List())}
            allAssignments={this.props.assignments}
            showOrToggle={i + 1 !== sets.size}
            toggleSetCondition={this.toggleSetCondition}
            removeAssignment={this.removeAssignment}
            moveAssignment={this.props.moveAssignment}
            disableSplit={sets.size >= MAX_SETS}
            setGlobalWarning={this.props.setGlobalWarning}
          />
        )
      })
      .toArray()
  }

  render() {
    const upperBound = transformScore(
      this.props.range.get('upper_bound'),
      this.props.triggerAssignment,
      true
    )
    const lowerBound = transformScore(
      this.props.range.get('lower_bound'),
      this.props.triggerAssignment,
      false
    )

    const rangeTitle = I18n.t('Scoring range %{upperBound} to %{lowerBound}', {
      upperBound,
      lowerBound,
    })

    return (
      <div className="cr-scoring-range">
        <ScreenReaderContent>
          <h2 ref={this.titleRef}>{rangeTitle}</h2>
        </ScreenReaderContent>
        <div className="cr-scoring-range__bounds">
          <div className="cr-scoring-range__bound cr-scoring-range__upper-bound">
            {this.renderUpperBound()}
          </div>
          <button
            type="button"
            className="cr-scoring-range__add-assignment-button"
            aria-label={I18n.t('Add Items to Score Range')}
            onClick={this.handleAddItems}
          >
            +
          </button>
          <div className="cr-scoring-range__bound cr-scoring-range__lower-bound">
            {this.renderLowerBound()}
          </div>
        </div>
        <div className="cr-scoring-range__assignments">{this.renderAssignmentSets()}</div>
      </div>
    )
  }
}

const ConnectedScoringRange = connect(null, actions)(ScoringRange)

export default ConnectedScoringRange
