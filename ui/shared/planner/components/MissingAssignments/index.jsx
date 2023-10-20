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

import React, {Component} from 'react'
import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import {connect} from 'react-redux'
import classnames from 'classnames'
import moment from 'moment-timezone'

import {IconWarningLine} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

import {courseShape, opportunityShape, sizeShape} from '../plannerPropTypes'
import {toggleMissingItems} from '../../actions'
import {useScope as useI18nScope} from '@canvas/i18n'
import PlannerItem from '../PlannerItem'
import buildStyle from './style'

const I18n = useI18nScope('planner')

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
    ? I18n.t(
        {
          one: 'Hide 1 missing item',
          other: 'Hide %{count} missing items',
        },
        {count}
      )
    : I18n.t(
        {
          one: 'Show 1 missing item',
          other: 'Show %{count} missing items',
        },
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
  course = {},
  responsiveSize = 'large',
  restrict_quantitative_data = false,
}) {
  return (
    <PlannerItem
      id={id}
      uniqueId={id}
      title={name}
      courseName={course.originalName}
      color={course.color}
      points={restrict_quantitative_data ? null : points_possible}
      html_url={html_url}
      date={due_at && moment(due_at).tz(timeZone)}
      timeZone={timeZone}
      associated_item={convertSubmissionType(submission_types)}
      simplifiedControls={true}
      isMissingItem={true}
      responsiveSize={responsiveSize}
    />
  )
}

MissingAssignment.propTypes = {
  id: string.isRequired,
  name: string.isRequired,
  points_possible: number.isRequired,
  html_url: string.isRequired,
  due_at: string,
  submission_types: arrayOf(string).isRequired,
  timeZone: string.isRequired,
  course: shape(courseShape),
  responsiveSize: sizeShape,
  restrict_quantitative_data: bool,
}

// Themeable doesn't support pure functional components
// and redux's connect throws an error with PureComponent
export class MissingAssignments extends Component {
  static propTypes = {
    courses: arrayOf(shape(courseShape)).isRequired,
    opportunities: shape(opportunityShape).isRequired,
    timeZone: string.isRequired,
    toggleMissing: func.isRequired,
    responsiveSize: string,
  }

  constructor(props) {
    super(props)
    this.style = buildStyle()
  }

  render() {
    const {courses, opportunities, timeZone, toggleMissing, responsiveSize = 'large'} = this.props
    const {items = [], missingItemsExpanded: expanded} = opportunities
    if (items.length === 0) {
      return null
    }

    return (
      <>
        <style>{this.style.css}</style>
        <section
          className={classnames(this.style.classNames.root, this.style.classNames[responsiveSize])}
        >
          {!expanded && (
            <div className={this.style.classNames.icon} data-testid="warning-icon">
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
            fluidWidth={true}
            onToggle={() => toggleMissing()}
            summary={
              <View data-testid="missing-data" margin="0 0 0 small">
                {getMissingItemsText(expanded, items.length)}
              </View>
            }
          >
            <View as="div" borderWidth="small none none none">
              {items.map(opp => (
                <MissingAssignment
                  key={opp.id}
                  {...opp}
                  course={courses.find(c => c.id === opp.course_id)}
                  timeZone={timeZone}
                  responsiveSize={responsiveSize}
                />
              ))}
            </View>
          </ToggleDetails>
        </section>
      </>
    )
  }
}

const mapStateToProps = ({courses, opportunities}) => ({
  courses,
  opportunities,
})

const mapDispatchToProps = {toggleMissing: toggleMissingItems}

const ConnectedMissingAssignments = connect(mapStateToProps, mapDispatchToProps)(MissingAssignments)
ConnectedMissingAssignments.theme = MissingAssignments.theme

export default ConnectedMissingAssignments
