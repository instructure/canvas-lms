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
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import I18n from 'i18n!appointment_groups'
import Typography from 'instructure-ui/lib/components/Typography'
import Button from 'instructure-ui/lib/components/Button'
import TimeBlockSelectRow from './TimeBlockSelectRow'
import coupleTimeFields from 'compiled/util/coupleTimeFields'
import TimeBlockListManager from 'compiled/calendar/TimeBlockListManager'
import 'jquery.instructure_date_and_time'

  class TimeBlockSelector extends React.Component {

    static propTypes = {
      className: PropTypes.string,
      timeData: PropTypes.arrayOf(PropTypes.object),
      onChange: PropTypes.func.isRequired
    };

    constructor (props) {
      super(props);
      this.newIdPrefix = 'NEW-';
      this.lastNewId = 0;
      this.state = {
        timeBlockRows: [{
          slotEventId: `${this.newIdPrefix}${this.lastNewId}`,
          timeData: {}
        }]
      };
      this.lastNewId++;
    }

    componentDidUpdate (prevProps, prevState) {
      if (prevState !== this.state) {
        this.props.onChange(this.state.timeBlockRows);
      }
    }

    getNewSlotData () {
      return this.state.timeBlockRows.reduce((acc, tbr) => {
        if (tbr.timeData.startTime && tbr.timeData.endTime) {
          acc.push([
            tbr.timeData.startTime,
            tbr.timeData.endTime,
            false
          ]);
        }
        return acc;
      }, []);
    }

    deleteRow = (slotEventId) => {
      const newRows = this.state.timeBlockRows.filter(e => e.slotEventId !== slotEventId);
      this.setState({
        timeBlockRows: newRows
      });
    }

    addRow = (timeData = {}) => {
      const newRows = [{
        slotEventId: `${this.newIdPrefix}${this.lastNewId}`,
        timeData
      }];
      this.setState({
        timeBlockRows: this.state.timeBlockRows.concat(newRows)
      }, () => this.lastNewId++);
    }

    addRowsFromBlocks = (timeBlocks) => {
      const newRows = timeBlocks.map(tb => ({
        slotEventId: `${this.newIdPrefix}${this.lastNewId++}`,
        timeData: tb
      }));
      // Make sure a new blank row is there as well.
      newRows.push({
        slotEventId: `${this.newIdPrefix}${this.lastNewId++}`,
        timeData: {}
      });
      this.setState({
        timeBlockRows: newRows
      });
    }

    formatDate = (date) => {
      if (date.toDate) {
        return date.toDate();
      }
      return date;
    }

    handleSlotDivision = () => {
      const node = ReactDOM.findDOMNode(this);
      const minuteValue = $('.TimeBlockSelector__DivideSection-Input', node).val();
      const timeManager = new TimeBlockListManager(this.getNewSlotData());
      timeManager.split(minuteValue);
      const newBlocks = timeManager.blocks.map(block => ({
        date: this.formatDate(block.start),
        startTime: this.formatDate(block.start),
        endTime: this.formatDate(block.end)
      }));
      this.addRowsFromBlocks(newBlocks);
    }

    handleSetData = (timeslotId, data) => {
      const newRows = this.state.timeBlockRows.slice();
      const rowToUpdate = newRows.find(r => r.slotEventId === timeslotId);
      rowToUpdate.timeData = data;
      this.setState({
        timeBlockRows: newRows
      });
    }

    render () {
      const classes = (this.props.className) ? `TimeBlockSelector ${this.props.className}` :
                                               'TimeBlockSelector';
      return (
        <div className={classes}>
          <div className="TimeBlockSelector__Rows">
            {this.props.timeData.map(timeBlock => (
              <TimeBlockSelectRow {...timeBlock} key={timeBlock.slotEventId} readOnly />
            ))}
            {this.state.timeBlockRows.map(timeBlock => (
              <TimeBlockSelectRow
                key={timeBlock.slotEventId}
                handleDelete={this.deleteRow}
                onBlur={this.addRow}
                setData={this.handleSetData}
                {...timeBlock}
              />
            ))}
          </div>
          <div className="TimeBlockSelector__DivideSection">
            <Typography>
              <label
                dangerouslySetInnerHTML={{
                  __html: I18n.t('Divide into equal slots of %{input_value} minutes. ', {
                    input_value: '<input class="TimeBlockSelector__DivideSection-Input" value="30" type="number"/>'
                  })
                }}
              />
              <Button
                size="small"
                onClick={this.handleSlotDivision}
              >{I18n.t('Create Slots')}</Button>
            </Typography>
          </div>
        </div>
      );
    }
  }

export default TimeBlockSelector
