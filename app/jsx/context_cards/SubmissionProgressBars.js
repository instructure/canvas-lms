/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import I18n from 'i18n!student_context_tray'
import classnames from 'classnames'
import Heading from 'instructure-ui/lib/components/Heading'
import Progress from 'instructure-ui/lib/components/Progress'
import Tooltip from 'instructure-ui/lib/components/Tooltip'
import Typography from 'instructure-ui/lib/components/Typography'
import Link from 'instructure-ui/lib/components/Link'

  class SubmissionProgressBars extends React.Component {
    static propTypes = {
      submissions: PropTypes.array.isRequired
    }

    static displayGrade (submission) {
      const {score, grade, excused} = submission
      const pointsPossible = submission.assignment.points_possible
      let display

      if (excused) {
        display = 'EX'
      } else if (grade.match(/%/)) {
        // Grade is a percentage, just show it
        display = grade
      } else if (grade.match(/complete/)) {
        // Grade is complete/incomplete, show icon
        display = SubmissionProgressBars.renderIcon(grade)
      } else {
        // Default to show score out of points possible
        display = `${score}/${pointsPossible}`
      }

      return display
    }

    static displayScreenreaderGrade (submission) {
      const {score, grade, excused} = submission
      const pointsPossible = submission.assignment.points_possible
      let display

      if (excused) {
        display = I18n.t('excused')
      } else if (grade.match(/%/) || grade.match(/complete/)) {
        // Grade is a percentage or in/complete, just show it
        display = grade
      } else {
        // Default to show score out of points possible
        display = `${score}/${pointsPossible}`
      }

      return display
    }

    static renderIcon (grade) {
      const iconClass = classnames({
        'icon-check': grade === 'complete',
        'icon-x': grade === 'incomplete'
      })

      return (
        <div>
          <span className='screenreader-only'>
            {I18n.t("%{grade}", {grade: grade})}
          </span>
          <i className={iconClass}></i>
        </div>
      )
    }

    render () {
      const {submissions} = this.props
      if (submissions.length > 0) {
        return (
          <section
            className="StudentContextTray__Section StudentContextTray-Progress">
            <Heading level="h4" as="h3" border="bottom">
              {I18n.t("Last %{length} Graded Items", {length: submissions.length})}
            </Heading>
            {submissions.map((submission) => {
              return (
                <div key={submission.id} className="StudentContextTray-Progress__Bar">
                  <Tooltip
                    tip={submission.assignment.name}
                    as={Link}
                    href={`${submission.assignment.html_url}/submissions/${submission.user_id}`}
                    placement="start"
                  >
                    <Progress
                      size="small"
                      successColor={false}
                      label={I18n.t('Grade')}
                      valueMax={submission.assignment.points_possible}
                      valueNow={submission.score || 0}
                      formatValueText={() => SubmissionProgressBars.displayScreenreaderGrade(submission)}
                      formatDisplayedValue={() => (
                        <Typography size="x-small" color="secondary">
                          {SubmissionProgressBars.displayGrade(submission)}
                        </Typography>
                      )}
                    />
                  </Tooltip>
                </div>
              )
            })}
          </section>
        )
      } else { return null }
    }
  }

export default SubmissionProgressBars
