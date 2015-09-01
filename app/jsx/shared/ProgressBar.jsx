/** @jsx React.DOM */

define([
  'react',
  'i18n!react_files',
  'classnames'
  ], function (React, I18n, classnames) {

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

    return ProgressBar;
});
