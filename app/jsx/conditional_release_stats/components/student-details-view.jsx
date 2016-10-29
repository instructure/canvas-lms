define([
  'react',
  'classnames',
  'instructure-ui/Spinner',
  'i18n!cyoe_assignment_sidebar',
  './student-assignment-item',
  '../shapes/index',
], (React, classNames, { default: Spinner }, I18n, StudentAssignmentItem, { assignmentShape, studentShape }) => {
  const { shape, string, number, arrayOf, func, bool } = React.PropTypes

  return class StudentDetailsView extends React.Component {
    static propTypes = {
      isLoading: bool,
      student: studentShape,
      triggerAssignment: shape({
        submission: shape({
          grade: string.isRequired,
          submitted_at: string.isRequired,
        }).isRequired,
        assignment: assignmentShape.isRequired,
      }),
      followOnAssignments: arrayOf(shape({
        score: number,
        trend: number,
        assignment: assignmentShape.isRequired,
      })),

      selectNextStudent: func.isRequired,
      selectPrevStudent: func.isRequired,
      unselectStudent: func.isRequired,
    }

    renderHeader () {
      return (
        <header className='crs-student-details__header'>
          <button onClick={this.props.unselectStudent} className='crs-breakdown__link crs-back-button'>
            <i aria-hidden className='icon-arrow-open-left'></i>
            {I18n.t('Back')}
          </button>
        </header>
      )
    }

    renderStudentProfile () {
      const { student, triggerAssignment } = this.props
      const { assignment } = triggerAssignment

      const studentAvatar = student.avatar_image_url || '/images/messages/avatar-50.png'
      const conversationUrl = `/conversations?context_id=course_${assignment.course_id}&user_id=${student.id}&user_name=${student.name}`

      return (
        <section className='crs-student-details__profile-content'>
          <button className='Button Button--icon-action student-details__prev-student' aria-label={I18n.t('view previous student')} onClick={this.props.selectPrevStudent} type='button'>
            <i aria-hidden className='icon-arrow-open-left'></i>
          </button>
          <div className='crs-student-details__profile-inner-content'>
            <img src={studentAvatar} aria-hidden className='crs-student-details__profile-image' />
            <h3 className='crs-student-details__name'>{student.name}</h3>
            <a title={I18n.t('Message Student')} target='_blank' href={conversationUrl} className='crs-breakdown__link'>
              <i aria-hidden className='icon-email crs-icon-email'></i>{I18n.t('Send Message')}
            </a>
          </div>
          <button className='Button Button--icon-action student-details__next-student' aria-label={I18n.t('view next student')} onClick={this.props.selectNextStudent} type='button'>
            <i aria-hidden className='icon-arrow-open-right'></i>
          </button>
        </section>
      )
    }

    renderTriggerAssignment () {
      const { student, triggerAssignment } = this.props
      const { assignment, submission } = triggerAssignment || {}

      const submissionUrl = `/courses/${assignment.course_id}/assignments/${assignment.id}/submissions/${student.id}`
      const submissionDate = (submission && I18n.l('date.formats.long', new Date(submission.submitted_at))) || I18n.t('Not Submitted')

      return (
        <section className='crs-student-details__score-content'>
          <h3 className='crs-student-details__score-number'>{submission.grade}</h3>
          <div className='crs-student-details__score-title'>{assignment.name}</div>
          <div className='crs-student-details__score-date'>{I18n.t('Submitted: %{submitDate}', { submitDate: submissionDate })}</div>
          <a title={I18n.t('View Student Submission')} target='_blank' href={submissionUrl} className='crs-breakdown__link'>{I18n.t('View Submission')}</a>
        </section>
      )
    }

    renderFollowOnAssignments () {
      const followOnAssignments = this.props.followOnAssignments || []
      return (
        <section>
          {
            followOnAssignments.map((item, i) => (
              <StudentAssignmentItem
                key={i}
                assignment={item.assignment}
                score={item.score}
                trend={item.trend}
              />
            ))
          }
        </section>
      )
    }

    renderContent () {
      if (this.props.isLoading) {
        return (
          <div className='crs-student-details__loading'>
           <Spinner title={I18n.t('Loading')} size='small' />
           <p>{I18n.t('Loading Data..')}</p>
         </div>
        )
      } else if (this.props.student) {
        return (
          <div>
            {this.renderStudentProfile()}
            {this.renderTriggerAssignment()}
            {this.renderFollowOnAssignments()}
          </div>
        )
      } else return null
    }

    render () {
      const isHidden = !this.props.student

      const studentDetailsClasses = classNames({
        'crs-student-details': true,
        'crs-student-details__hidden': isHidden,
      })

      return (
        <div className={studentDetailsClasses}>
          {this.renderHeader()}
          {this.renderContent()}
        </div>
      )
    }
  }
})
