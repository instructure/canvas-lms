define([
  'react',
  'timezone'
], (React, tz) => {
  class DatetimeDisplay extends React.Component {
    render () {
      let datetime = this.props.datetime instanceof Date ? this.props.datetime.toString() : this.props.datetime
      return (
        <span className='DatetimeDisplay'>
          {tz.format(datetime, this.props.format)}
        </span>
      );
    }
  };

  DatetimeDisplay.propTypes = {
    datetime: React.PropTypes.oneOfType([
      React.PropTypes.string,
      React.PropTypes.instanceOf(Date)
    ]),
    format: React.PropTypes.string
  };

  DatetimeDisplay.defaultProps = {
    format: '%c'
  };

  return DatetimeDisplay;
});
