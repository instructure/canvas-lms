define([
  'react',
  'classnames',
  'i18n!cyoe_assignment_sidebar',
], (React, classNames, I18n) => {
  const { object, func, number } = React.PropTypes

  return class StudentRangeItem extends React.Component {
    static get propTypes () {
      return {
        student: object.isRequired,
        onSelect: func.isRequired,
        studentIndex: number.isRequired,
      }
    }

    constructor () {
      super()
      this.onSelect = this.onSelect.bind(this)
    }

    onSelect () {
      this.props.onSelect(this.props.studentIndex)
    }

    render () {
      const avatar = this.props.student.user.avatar_image_url || '/images/messages/avatar-50.png' // default

      const progressClasses = classNames({
        'crs-student__progress-icon': true,
        'crs-student__progress-icon__positive': this.props.student.progress === 1,
        'crs-student__progress-icon__neutral': this.props.student.progress === 0,
        'crs-student__progress-icon__negative': this.props.student.progress === -1,
      })

      return (
        <div className='crs-student-range__item'>
          <img src={avatar} className='crs-student__avatar' />
          <button
            className='crs-student__name crs-link-button'
            onClick={this.onSelect}
            aria-label={I18n.t('Select student %{name}', { name: this.props.student.user.name })}
          >
            {this.props.student.user.name}
          </button>
          <span className={progressClasses}></span>
        </div>
      )
    }
  }
})
