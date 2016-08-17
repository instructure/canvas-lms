define([
  'react',
  'classnames',
  'i18n!choose_mastery_path',
], (React, classNames, I18n) => {
  const { func, bool } = React.PropTypes

  return class SelectButton extends React.Component {
    static propTypes = {
      isSelected: bool,
      isDisabled: bool,
      onSelect: func.isRequired,
    }

    constructor () {
      super()
      this.onClick = this.onClick.bind(this)
    }

    onClick () {
      const { isSelected, isDisabled } = this.props
      if (!isSelected && !isDisabled) {
        this.props.onSelect()
      }
    }

    render () {
      const { isSelected, isDisabled } = this.props
      const isBadge = isSelected || isDisabled

      const btnClasses = classNames({
        'btn': !isBadge,
        'btn-primary': !isBadge,
        'ic-badge': isBadge,
        'cmp-button': true,
        'cmp-button__selected': isSelected,
        'cmp-button__disabled': isDisabled,
      })

      let text = ''

      if (isSelected) {
        text = I18n.t('Selected')
      } else if (isDisabled) {
        text = I18n.t('Unavailable')
      } else {
        text = I18n.t('Select')
      }

      return (
        <button className={btnClasses} onClick={this.onClick} disabled={isDisabled}>
          {text}
        </button>
      )
    }
  }
})
