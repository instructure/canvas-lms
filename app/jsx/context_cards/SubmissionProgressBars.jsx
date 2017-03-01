define([
  'react',
  'i18n!student_context_tray',
  'classnames',
  'instructure-ui'
], (React, I18n, classnames, { Heading, Progress, Tooltip, Typography, Link }) => {
  class SubmissionProgressBars extends React.Component {
    static propTypes = {
      submissions: React.PropTypes.array.isRequired
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
                    placement="left"
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

  return SubmissionProgressBars
})
