define([
  'react',
  'underscore',
  'i18n!edit_timezone'
], function (React, _, I18n) {
  const { array } = React.PropTypes;

  class TimeZoneSelect extends React.Component {

    containsZone (timezones, zone) {
      return (_.find(timezones, (z) => {return z.name === zone.name}));
    }

    filterTimeZones (timezones, priority_timezones) {
      return timezones.filter((zone) => {
        return !this.containsZone(priority_timezones, zone);
      });
    }

    renderOptions (timezones) {
      return timezones.map((zone) => {
        return <option key={zone.name} value={zone.name}>{zone.localized_name}</option>
      });
    }

    render () {
      const timeZonesWithoutPriorities = this.filterTimeZones(this.props.timezones, this.props.priority_timezones);

      return (
        <select {...this.props}>
          <optgroup label={I18n.t('Common Timezones')}>
            {this.renderOptions(this.props.priority_timezones)}
          </optgroup>
          <optgroup label={I18n.t('Other Timezones')}>
            {this.renderOptions(timeZonesWithoutPriorities)}
          </optgroup>
        </select>
      );
    }
  }

  TimeZoneSelect.propTypes = {
    timezones: array.isRequired,
    priority_timezones: array.isRequired
  };

  return TimeZoneSelect;
});
