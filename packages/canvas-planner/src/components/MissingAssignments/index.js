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
import {arrayOf, func, number, shape, string} from 'prop-types'
import {connect} from 'react-redux'
import classnames from 'classnames'
import moment from 'moment-timezone'

import {colors} from '@instructure/canvas-theme'
import {IconWarningLine} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {themeable} from '@instructure/ui-themeable'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

import {courseShape, opportunityShape} from '../plannerPropTypes'
import {toggleMissingItems} from '../../actions'
import formatMessage from '../../format-message'
import PlannerItem from '../PlannerItem'
import responsiviser from '../responsiviser'
import styles from './styles.css'
import theme from './theme'

export const convertSubmissionType = submissionTypes => {
  if (submissionTypes?.length > 0) {
    switch (submissionTypes[0]) {
      case 'discussion_topic':
        return 'Discussion'
      case 'online_quiz':
        return 'Quiz'
    }
  }
  return 'Assignment'
}

export const getMissingItemsText = (isExpanded, count) => {
  return isExpanded
    ? formatMessage(
        `{
                  count, plural,
                  one {Hide # missing item}
                  other {Hide # missing items}
               }`,
        {count}
      )
    : formatMessage(
        `{
                  count, plural,
                  one {Show # missing item}
                  other {Show # missing items}
               }`,
        {count}
      )
}

function MissingAssignment({
  id,
  name,
  points_possible,
  html_url,
  due_at,
  submission_types,
  timeZone,
  course = {}
}) {
  return (
    <PlannerItem
      id={id}
      uniqueId={id}
      title={name}
      courseName={course.originalName}
      color={course.color}
      points={points_possible}
      html_url={html_url}
      date={moment(due_at).tz(timeZone)}
      timeZone={timeZone}
      associated_item={convertSubmissionType(submission_types)}
      simplifiedControls
      isMissingItem
    />
  )
}

MissingAssignment.propTypes = {
  id: string.isRequired,
  name: string.isRequired,
  points_possible: number.isRequired,
  html_url: string.isRequired,
  due_at: string.isRequired,
  submission_types: arrayOf(string).isRequired,
  timeZone: string.isRequired,
  course: shape(courseShape)
}

// Themeable doesn't support pure functional components
export class MissingAssignments extends PureComponent {
  static propTypes = {
    courses: arrayOf(shape(courseShape)).isRequired,
    opportunities: shape(opportunityShape).isRequired,
    timeZone: string.isRequired,
    toggleMissing: func.isRequired,
    responsiveSize: string
  }

  render() {
    const {courses, opportunities, timeZone, toggleMissing, responsiveSize = 'large'} = this.props
    const {items = [], missingItemsExpanded: expanded} = opportunities
    if (items.length === 0) {
      return null
    }

    return (
      <section className={classnames(styles.root, styles[responsiveSize])}>
        {!expanded && (
          <div className={styles.icon} data-testid="warning-icon">
            <View margin="0 small 0 0">
              <PresentationContent>
                <IconWarningLine color="error" />
              </PresentationContent>
            </View>
          </div>
        )}
        <ToggleDetails
          id="MissingAssignments"
          expanded={expanded}
          data-testid="missing-item-info"
          fluidWidth
          onToggle={() => toggleMissing()}
          summary={
            <View data-testid="missing-data" margin="0 0 0 x-small">
              {getMissingItemsText(expanded, items.length)}
            </View>
          }
          theme={{
            textColor: colors.textBrand,
            iconColor: colors.brand
          }}
        >
          <View as="div" borderWidth="small none none none">
            {items.map(opp => (
              <MissingAssignment
                key={opp.id}
                {...opp}
                course={courses.find(c => c.id === opp.course_id)}
                timeZone={timeZone}
              />
            ))}
          </View>
        </ToggleDetails>
      </section>
    )
  }
}

const mapStateToProps = ({courses, opportunities}) => ({
  courses,
  opportunities
})

const mapDispatchToProps = {toggleMissing: toggleMissingItems}

const ResponsiveMissingAssignment = responsiviser()(MissingAssignments)
const ThemeableMissingAssignments = themeable(theme, styles)(ResponsiveMissingAssignment)
const ConnectedMissingAssignments = connect(
  mapStateToProps,
  mapDispatchToProps
)(ThemeableMissingAssignments)
ConnectedMissingAssignments.theme = ThemeableMissingAssignments.theme

export default ConnectedMissingAssignments
