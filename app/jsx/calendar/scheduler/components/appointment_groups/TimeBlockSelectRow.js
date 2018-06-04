/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!appointment_groups'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconXSolid from '@instructure/ui-icons/lib/Solid/IconX'
import coupleTimeFields from 'compiled/util/coupleTimeFields'
import 'jquery.instructure_date_and_time'

  const dateToString = (dateObj, format) => {
    if (!dateObj) {
      return '';
    }
    return I18n.l(`date.formats.${format}`, $.fudgeDateForProfileTimezone(dateObj));
  };

  const timeToString = (dateObj, format) => {
    if (!dateObj) {
      return '';
    }
    return I18n.l(`time.formats.${format}`, $.fudgeDateForProfileTimezone(dateObj));
  };

  class TimeBlockSelectorRow extends React.Component {

    static propTypes = {
      timeData: PropTypes.shape({
        date: PropTypes.date,
        startTime: PropTypes.date,
        endTime: PropTypes.date
      }).isRequired,
      slotEventId: PropTypes.string,
      readOnly: PropTypes.bool,
      onBlur: PropTypes.func,
      handleDelete: PropTypes.func,
      setData: PropTypes.func
    };

    constructor (props) {
      super(props);
      this.state = {};
    }

    componentDidMount () {
      const options = {};
      if (this.props.readOnly) {
        options.disableButton = true;
      }
      $(this.date).date_field(options);
      $(this.startTime).time_field();
      $(this.endTime).time_field();
      coupleTimeFields($(this.startTime), $(this.endTime), $(this.date));
    }

    prepareData = () => {
      const data = {
        date: $(this.date).data('date'),
        startTime: $(this.startTime).data('date'),
        endTime: $(this.endTime).data('date')
      };

      this.props.setData && this.props.setData(this.props.slotEventId, data);
    }

    handleDelete = (e) => {
      e.preventDefault();
      this.props.handleDelete && this.props.handleDelete(this.props.slotEventId);
    }

    handleFieldBlur = (e) => {
      // In some browsers, we actually need to handle the update of data on blur
      this.prepareData();
      // Only call the onBlur if it's not blank, and it's the last one in the list.
      if (!$(e.target).data('blank') && $(e.target).closest('.TimeBlockSelectorRow').is(':last-child')) {
        this.props.onBlur && this.props.onBlur();
      }
    }

    render () {
      return (
        <div className="TimeBlockSelectorRow">
          <div className="TimeBlockSelectorColumn">
            <input
              type="text"
              disabled={this.props.readOnly}
              aria-disabled={this.props.readOnly ? 'true' : null}
              ref={(c) => { this.date = c; }}
              className="TimeBlockSelectorRow__Date"
              onChange={this.prepareData}
              onBlur={this.handleFieldBlur}
              placeholder={I18n.t('Date')}
              defaultValue={dateToString(this.props.timeData.date, 'medium')}
            />
          </div>
          <div className="TimeBlockSelectorColumn">
            <input
              type="text"
              disabled={this.props.readOnly}
              aria-disabled={this.props.readOnly ? 'true' : null}
              ref={(c) => { this.startTime = c; }}
              className="TimeBlockSelectorRow__StartTime"
              onChange={this.prepareData}
              onBlur={this.handleFieldBlur}
              placeholder={I18n.t('Start Time')}
              defaultValue={timeToString(this.props.timeData.startTime, 'tiny')}
            />
          </div>
          <div className="TimeBlockSelectorColumn" >
            <Text>
              {I18n.t('to')}
            </Text>
          </div>
          <div className="TimeBlockSelectorColumn">
            <input
              type="text"
              disabled={this.props.readOnly}
              aria-disabled={this.props.readOnly ? 'true' : null}
              ref={(c) => { this.endTime = c; }}
              className="TimeBlockSelectorRow__EndTime"
              onChange={this.prepareData}
              onBlur={this.handleFieldBlur}
              placeholder={I18n.t('End Time')}
              defaultValue={timeToString(this.props.timeData.endTime, 'tiny')}
            />
          </div>
          <div className="TimeBlockSelectorColumn">
            {
              !this.props.readOnly && (
                  <Button ref={(c) => { this.deleteBtn = c; }} variant="icon" onClick={this.handleDelete}>
                    <IconXSolid title="{I18n.t('Delete Time Range')}" />
                  </Button>
              )
            }
          </div>
        </div>
      );
    }
  }

export default TimeBlockSelectorRow
