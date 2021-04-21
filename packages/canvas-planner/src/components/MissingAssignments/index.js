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
import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import {connect} from 'react-redux'
import classnames from 'classnames'
import moment from 'moment-timezone'

import {Button} from '@instructure/ui-buttons'
import {colors} from '@instructure/canvas-theme'
import {IconWarningLine} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {themeable} from '@instructure/ui-themeable'
import {Spinner} from '@instructure/ui-spinner'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {courseShape, opportunityShape} from '../plannerPropTypes'

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

// Keeping this around until we're 100% sure we don't need it
export function NextMissingAssignmentsLink({hasMore, loadMoreOpportunities, loading}) {
  if (!hasMore) return null

  if (loading)
    return (
      <Spinner renderTitle={() => formatMessage('Loading more missing assignments')} size="small" />
    )

  return (
    <Button variant="link" onClick={() => loadMoreOpportunities()}>
      {formatMessage('Show More')}
    </Button>
  )
}

NextMissingAssignmentsLink.propTypes = {
  hasMore: bool.isRequired,
  loadMoreOpportunities: func.isRequired,
  loading: bool.isRequired
}

// Themeable doesn't support pure functional components
export class MissingAssignments extends PureComponent {
  static propTypes = {}

  constructor(props) {
    super(props)
    this.state = {
      expanded: false
    }
  }

  render() {
    const {
      courses,
      loadingOpportunities,
      opportunities,
      timeZone,
      responsiveSize = 'large'
    } = this.props
    const {items = []} = opportunities
    if (items.length === 0) {
      return null
    }

    return (
      <section className={classnames(styles.root, styles[responsiveSize])}>
        {!this.state.expanded && (
          <div className={styles.icon} data-testid="warning-icon">
            <View margin="0 small 0 0">
              <PresentationContent>
                <IconWarningLine color="error" />
              </PresentationContent>
            </View>
          </div>
        )}
        <ToggleDetails
          expanded={this.state.expanded}
          fluidWidth
          onToggle={(_, expanded) => this.setState({expanded})}
          summary={
            <View margin="0 0 0 x-small">
              {getMissingItemsText(this.state.expanded, items.length)}
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
          <div className={styles.moreButton}>
            <NextMissingAssignmentsLink
              hasMore={false}
              loadMoreOpportunities={() => {}}
              loading={loadingOpportunities}
            />
          </div>
        </ToggleDetails>
      </section>
    )
  }
}

MissingAssignments.propTypes = {
  courses: arrayOf(shape(courseShape)).isRequired,
  loadingOpportunities: bool.isRequired,
  opportunities: shape(opportunityShape).isRequired,
  timeZone: string.isRequired,
  responsiveSize: string
}

const mapStateToProps = ({courses, loading: {loadingOpportunities}, opportunities}) => ({
  courses,
  loadingOpportunities,
  opportunities
})

const ResponsiveMissingAssignment = responsiviser()(MissingAssignments)
const ThemeableMissingAssignments = themeable(theme, styles)(ResponsiveMissingAssignment)
const ConnectedMissingAssignments = connect(mapStateToProps)(ThemeableMissingAssignments)
ConnectedMissingAssignments.theme = ThemeableMissingAssignments.theme

export default ConnectedMissingAssignments
