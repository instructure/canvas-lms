define([
  'react',
  'i18n!student_context_tray',
  'classnames',
  'instructure-ui'
], (React, I18n, classnames,
    { Heading, Rating: InstUIRating, Typography }
   ) => {
  class Rating extends React.Component {
    static propTypes = {
      analytics: React.PropTypes.object,
      label: React.PropTypes.string,
      metricName: React.PropTypes.string
    }

    static defaultProps = {
      analytics: {}
    }

    get valueNow () {
      return this.props.analytics[this.props.metricName]
    }

    formatValueText (currentRating, maxRating) {
      const valueText = {}
      valueText[I18n.t('High')] = currentRating === maxRating
      valueText[I18n.t('Moderate')] = currentRating === 2
      valueText[I18n.t('Low')] = currentRating === 1
      valueText[I18n.t('None')] = currentRating === 0
      return classnames(valueText)
    }

    render () {
      if (typeof this.valueNow !== 'undefined') {
        return (
          <div
            className="StudentContextTray-Rating">
            <Heading level="h5" tag="h4">
              {this.props.label}
            </Heading>
            <div className="StudentContextTray-Rating__Stars">
              <InstUIRating
                formatValueText={this.formatValueText}
                label={this.props.label}
                valueNow={this.valueNow}
                valueMax={3}
              />
              <div>
                <Typography size="small" color="brand">
                  {this.formatValueText(this.valueNow, 3)}
                </Typography>
              </div>
            </div>
          </div>
        )
      } else { return null }
    }
  }

  return Rating
})
