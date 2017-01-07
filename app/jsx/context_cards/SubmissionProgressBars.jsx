define([
  'react',
  'i18n!student_context_tray',
  'classnames',
  'instructure-ui/Heading',
  'instructure-ui/Progress',
  'instructure-ui/Typography'
], (React, I18n, classnames, { default: Heading }, { default: Progress }, { default: Typography }) => {

  class SubmissionProgressBars extends React.Component {
    static propTypes = {
      submissions: React.PropTypes.array.isRequired
    }

    displayGrade (submission) {
      const {score, grade, excused} = submission
      const pointsPossible = submission.assignment.points_possible

      if (excused) {
        return 'EX'
      } else if (grade.match(/\%/)) {
        // Grade is a percentage, just show it
        return grade
      } else if (grade.match(/complete/)) {
        // Grade is complete/incomplete, show icon
        return this.renderIcon(grade)
      } else {
        // Default to show score out of points possible
        return `${score}/${pointsPossible}`
      }
    }

    renderIcon (grade) {
      const iconClass= classnames({
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
      if (this.props.submissions.length > 0) {
        return (
          <section
            className="StudentContextTray__Section StudentContextTray-Progress">
            <Heading level="h4" tag="h3" border="bottom">
              {I18n.t("Last %{length} Graded Items", {length: this.props.submissions.length})}
            </Heading>
            {this.props.submissions.map((submission) => {
              return (
                <div key={submission.id} className="StudentContextTray-Progress__Bar">
                  <Progress
                    size="small"
                    successColor={false}
                    label={I18n.t('Grade')}
                    valueMax={submission.assignment.points_possible}
                    valueNow={submission.score || 0}
                    formatValueText={() => {return this.displayGrade(submission)} }
                    formatDisplayedValue={() => {
                      return (
                        <Typography size="x-small" color="secondary">
                          {this.displayGrade(submission)}
                        </Typography>
                      )
                    }}
                  />
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
