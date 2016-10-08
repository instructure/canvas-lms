define([
  'react',
  'classnames',
  'i18n!choose_mastery_path',
  './assignment',
  './select-button',
  '../shapes/assignment-shape',
], (React, classNames, I18n, Assignment, SelectButton, assignmentShape) => {
  const { func, number, arrayOf } = React.PropTypes

  return class PathOption extends React.Component {
    static propTypes = {
      assignments: arrayOf(assignmentShape).isRequired,
      optionIndex: number.isRequired,
      setId: number.isRequired,
      selectedOption: number,
      selectOption: func.isRequired,
    }

    constructor () {
      super()
      this.selectOption = this.selectOption.bind(this)
    }

    selectOption () {
      this.props.selectOption(this.props.setId)
    }

    render () {
      const { selectedOption, setId, optionIndex } = this.props
      const disabled = selectedOption !== null && selectedOption !== undefined && selectedOption !== setId
      const selected = selectedOption === setId

      const optionClasses = classNames({
        'item-group-container': true,
        'cmp-option': true,
        'cmp-option__selected': selected,
        'cmp-option__disabled': disabled,
      })

      return (
        <div className={optionClasses}>
          <div className='item-group-condensed context_module'>
            <div className='ig-header'>
              <span className='name'>
                {I18n.t('Option %{index}', { index: optionIndex + 1 })}
              </span>
              <SelectButton isDisabled={disabled} isSelected={selected} onSelect={this.selectOption} />
            </div>
            <ul className='ig-list'>
              {this.props.assignments.map((assg, i) => (
                <Assignment
                  key={i}
                  assignment={assg}
                  isSelected={selected}
                />
              ))}
            </ul>
          </div>
        </div>
      )
    }
  }
})
