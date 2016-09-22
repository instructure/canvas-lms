define([
  'react',
  'classnames',
  'i18n!cyoe_assignment_sidebar',
], (React, classNames, I18n) => {
  const { object, func, number } = React.PropTypes

  return class StudentRangeItem extends React.Component {
    static propTypes = {
      student: object.isRequired,
      studentIndex: number.isRequired,

      selectStudent: func.isRequired,
    }

    constructor () {
      super()
      this.selectStudent = this.selectStudent.bind(this)
    }

    selectStudent () {
      this.props.selectStudent(this.props.studentIndex)
    }

    render () {
      const avatar = this.props.student.user.avatar_image_url || '/images/messages/avatar-50.png' // default
      const { trend } = this.props.student

      const trendClasses = classNames({
        'crs-student__trend-icon': true,
        'crs-student__trend-icon__positive': trend === 1,
        'crs-student__trend-icon__neutral': trend === 0,
        'crs-student__trend-icon__negative': trend === -1,
      })

      const showTrend = trend !== null && trend !== undefined

      return (
        <div className='crs-student-range__item'>
          <img src={avatar} className='crs-student__avatar' onClick={this.selectStudent}/>
          <button
            className='crs-student__name crs-link-button'
            onClick={this.selectStudent}
            aria-label={I18n.t('Select student %{name}', { name: this.props.student.user.name })}
          >
          {this.props.student.user.name}
          </button>
          {showTrend && (<span className={trendClasses}></span>)}
        </div>
      )
    }
  }
})
