import React from 'react'
import I18n from 'i18n!react_files'
import classnames from 'classnames'

    var ProgressBar = React.createClass({

      render () {
        var barClasses = classnames({
          'progress-bar__bar': true,
          'almost-done': this.props.progress === 100
        });

        var containerClasses = classnames({
          'progress-bar__bar-container': true,
          'almost-done': this.props.progress === 100
        });

        return (
          <div ref='container' className={containerClasses}>
            <div
              ref='bar'
              className={barClasses}
              role='progressbar'
              aria-valuenow={this.props.progress}
              aria-valuemin="0"
              aria-valuemax="100"
              aria-label={this.props['aria-label'] || ''}
              style={{
                width: Math.min(this.props.progress, 100) + '%'
              }}
            />
          </div>
        );
      }
  });

export default ProgressBar
