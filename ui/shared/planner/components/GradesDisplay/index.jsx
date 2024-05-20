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

import React, {Component} from 'react'
import {bool, string, arrayOf, shape} from 'prop-types'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import {courseShape} from '../plannerPropTypes'
import buildStyle from './style'
import {useScope as useI18nScope} from '@canvas/i18n'
import ErrorAlert from '../ErrorAlert'

const I18n = useI18nScope('planner')

export default class GradesDisplay extends Component {
  constructor(props) {
    super(props)
    this.style = buildStyle()
  }

  static propTypes = {
    loading: bool,
    loadingError: string,
    courses: arrayOf(shape(courseShape)).isRequired,
  }

  static defaultProps = {
    loading: false,
  }

  scoreString = (score, useThisCoercedLetterGradeInstead = null) => {
    const fixedScore = parseFloat(score)
    // eslint-disable-next-line no-restricted-globals
    if (isNaN(fixedScore)) return I18n.t('No Grade')
    return useThisCoercedLetterGradeInstead || `${fixedScore.toFixed(2)}%`
  }

  renderSpinner = () => (
    <View as="div" textAlign="center" margin="0 0 large 0">
      <Spinner renderTitle={() => I18n.t('Grades are loading')} size="small" />
    </View>
  )

  renderCaveat = () => {
    if (this.props.loading) return
    if (this.props.courses.some(course => course.hasGradingPeriods)) {
      return (
        <View as="div" textAlign="center">
          <Text size="x-small" fontStyle="italic">
            {I18n.t('*Only most recent grading period shown.')}
          </Text>
        </View>
      )
    }
  }

  renderGrades = () => {
    if (this.props.loadingError) return
    return this.props.courses.map(course => {
      const courseNameStyles = {
        borderBottom: `solid thin`,
        borderBottomColor: course.color,
      }

      return (
        <View key={course.id} as="div" margin="0 0 large 0">
          <div className={this.style.classNames.course} style={courseNameStyles}>
            <Link isWithinText={false} size="small" href={`${course.href}/grades`}>
              <Text transform="uppercase">{course.shortName}</Text>
            </Link>
          </div>
          <Text as="div" size="large" weight="light" data-testid="my-grades-score">
            {course.restrictQuantitativeData
              ? this.scoreString(course.score, course.scoreThasWasCoercedToLetterGrade)
              : this.scoreString(course.score)}
          </Text>
        </View>
      )
    })
  }

  renderError = () => {
    if (this.props.loadingError) {
      return (
        <ErrorAlert error={this.props.loadingError}>{I18n.t('Error loading grades')}</ErrorAlert>
      )
    }
  }

  render = () => (
    <>
      <style>{this.style.css}</style>
      <View>
        {this.renderError()}
        <View textAlign="center">
          <Heading level="h2" margin="0 0 large 0">
            <Text size="medium" weight="bold">
              {I18n.t('My Grades')}
            </Text>
          </Heading>
        </View>
        {this.props.loading ? this.renderSpinner() : this.renderGrades()}
        {this.renderCaveat()}
      </View>
    </>
  )
}
