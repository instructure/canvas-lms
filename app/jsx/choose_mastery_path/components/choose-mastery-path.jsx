define([
  'react',
  'i18n!choose_mastery_path',
  './path-option',
  '../shapes/option-shape',
], (React, I18n, PathOption, optionShape) => {
  const { func, number, arrayOf } = React.PropTypes

  return class ChooseMasteryPath extends React.Component {
    static propTypes = {
      options: arrayOf(optionShape).isRequired,
      selectedOption: number,
      selectOption: func.isRequired,
    }

    renderHeader () {
      const selectedOption = this.props.selectedOption
      if (selectedOption !== null && selectedOption !== undefined) {
        return (
          <h2>{I18n.t('Assignment Path Selected')}</h2>
        )
      } else {
        return (
          <div>
            <h2>{I18n.t('Choose Assignment Path')}</h2>
            <p><em>{I18n.t('Select one of the options:')}</em></p>
          </div>
        )
      }
    }

    render () {
      return (
        <div className='cmp-wrapper'>
          {this.renderHeader()}
          {this.props.options.map((path, i) => (
            <PathOption
              key={path.setId}
              optionIndex={i}
              setId={path.setId}
              assignments={path.assignments}
              selectOption={this.props.selectOption}
              selectedOption={this.props.selectedOption}
            />
          ))}
        </div>
      )
    }
  }
})
