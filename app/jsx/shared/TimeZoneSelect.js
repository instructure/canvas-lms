/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import PropTypes from 'prop-types'
import _ from 'underscore'
import I18n from 'i18n!edit_timezone'

  const { array } = PropTypes;

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

export default TimeZoneSelect
