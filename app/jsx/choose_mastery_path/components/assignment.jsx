define([
  'react',
  'classnames',
  'i18n!choose_mastery_path',
  '../shapes/assignment-shape',
], (React, classNames, I18n, assignmentShape) => {
  const { shape, date, string, object, bool } = React.PropTypes

  return class Assignment extends React.Component {
    static propTypes = {
      assignment: assignmentShape.isRequired,
      isSelected: bool,
    }

    renderTitle () {
      if (this.props.isSelected) {
        return (
          <a href={`/courses/${this.props.assignment.context_id}/assignments/${this.props.assignment.assignmentId}`} title={this.props.assignment.name} className='item_name cmp-assignment__title-link'>
            {this.props.assignment.name}
          </a>
        )
      } else {
        return (
          <span className='item_name'>
            {this.props.assignment.name}
          </span>
        )
      }
    }

    render () {
      const dueAt = this.props.assignment.due_at
      const points = this.props.assignment.points_possible
      const date = dueAt && I18n.l('date.formats.short', dueAt)

      const assgClasses = classNames(
        'cmp-assignment',
        'context_module_item',
        this.props.assignment.category.contentTypeClass
      )

      return (
        <li className={assgClasses}>
          <div className='ig-row'>
            <span className='type_icon' title={this.props.assignment.category.label}>
              <span className='ig-type-icon'>
                <i className={`icon-${this.props.assignment.category.id}`}></i>
              </span>
            </span>
            <div className='ig-info'>
              <div className='module-item-title'>
                {this.renderTitle()}
              </div>
              <div className='ig-details'>
                {!!dueAt && (
                  <div className='due_date_display ig-details__item'>
                    <strong>{I18n.t('Due')}</strong>
                    <span>{date}</span>
                  </div>
                )}
                { points != null && (
                  <div key='points' className='points_possible_display ig-details__item'>{I18n.t('%{points} pts', { points: points })}</div>
                )}
              </div>
            </div>
          </div>
        </li>
      )
    }
  }
})
