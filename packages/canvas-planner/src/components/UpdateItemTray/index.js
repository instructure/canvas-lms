/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React, { Component } from 'react';
import _ from 'lodash';
import themeable from '@instructure/ui-themeable/lib';
import View from '@instructure/ui-layout/lib/components/View';
import FormFieldGroup from '@instructure/ui-forms/lib/components/FormFieldGroup';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import Button from '@instructure/ui-buttons/lib/components/Button';
import formatMessage from '../../format-message';
import PropTypes from 'prop-types';
import TextInput from '@instructure/ui-forms/lib/components/TextInput';
import Select from '@instructure/ui-forms/lib/components/Select';
import TextArea from '@instructure/ui-forms/lib/components/TextArea';
import DateTimeInput from '@instructure/ui-forms/lib/components/DateTimeInput';
import moment from 'moment-timezone';

import { courseShape } from '../plannerPropTypes';
import styles from './styles.css';
import theme from './theme.js';

export class UpdateItemTray extends Component {
  static propTypes = {
    courses: PropTypes.arrayOf(PropTypes.shape(courseShape)).isRequired,
    noteItem: PropTypes.object,
    onSavePlannerItem: PropTypes.func.isRequired,
    onDeletePlannerItem: PropTypes.func.isRequired,
    locale: PropTypes.string.isRequired,
    timeZone: PropTypes.string.isRequired,
  };

  constructor (props) {
    super(props);
    const updates = this.getNoteUpdates(props);
    this.state = {
      updates,
      titleMessages: [],
      dateMessages: [],
    };
  }

  componentWillReceiveProps (nextProps) {
    if (!_.isEqual(this.props.noteItem, nextProps.noteItem)) {
      const updates = this.getNoteUpdates(nextProps);
      this.setState({updates}, this.updateMessages);
    }
  }

  editingExistingNote () {
    return this.props.noteItem && this.props.noteItem.uniqueId
  }

  getNoteUpdates (props) {
    const updates = _.cloneDeep(props.noteItem) || {};
    if (updates.context) {
      updates.courseId = updates.context.id;
      delete updates.context;
    }
    if (!updates.date) {
       updates.date = moment.tz(props.timeZone).endOf('day');
    }
    return updates;
  }

  updateMessages = () => {
    if (!this.state.updates.date) {
      this.setState({dateMessages: [{type: 'error', text: formatMessage('Date is required')}]});
    } else {
      this.setState({dateMessages: []});
    }
  }

  handleSave = () => {
    const updates = Object.assign({}, this.state.updates);
    if (updates.courseId) {
      updates.context = { id: updates.courseId };
    } else {
      updates.context = { id: null };
    }
    updates.date = updates.date.toISOString();
    delete updates.courseId;
    this.props.onSavePlannerItem(updates);
  }

  handleChange = (field, value) => {
    this.setState({
      updates: {
        ...this.state.updates,
        [field]: value
      }
    }, this.updateMessages);
  }

  handleCourseIdChange = (e, option) => {
    if (!option) return
    let value = option.value;
    if (value === 'none') value = undefined;
    this.handleChange('courseId', value);
  }

  handleTitleChange = (e) => {
    const value = e.target.value;
    if (value === '') {
      this.setState({
        titleMessages: [{type: 'error', text: formatMessage('title is required')}]
      });
    } else {
        this.setState({titleMessages: []});
    }
    this.handleChange('title', value);
  }

  handleDateChange = (e, isoDate) => {
    const value = isoDate || '';
      this.handleChange('date', moment.tz(value, this.props.timeZone));
  }

  invalidDateTimeMessage (rawDateValue, rawTimeValue) {
    let errmsg;
    if (rawDateValue) {
      errmsg = formatMessage("#{date} is not a valid date.", {date: rawDateValue});
    } else {
      errmsg = formatMessage('You must provide a date and time.');
    }
    return errmsg;
  }
  // separating the function from the bound callback is necessary so I can spy
  // on invalidDateTimeMessage in unit tests.
  onInvalidDateTimeMessage = this.invalidDateTimeMessage.bind(this);

  handleDeleteClick = () => {
    // eslint-disable-next-line no-restricted-globals
    if (confirm(formatMessage('Are you sure you want to delete this planner item?'))) {
      this.props.onDeletePlannerItem(this.props.noteItem);
    }
  }

  findCurrentValue (field) {
    return this.state.updates[field] || '';
  }

  isValid () {
    if (this.state.updates.title &&
        this.state.updates.date && this.state.updates.date.isValid()) {
      return this.state.updates.title.replace(/\s/g, '').length > 0;
    }
    return false;
  }

  renderDeleteButton () {
    if (!this.editingExistingNote()) return;
    return <Button
      variant="light"
      margin="0 x-small 0 0"
      onClick={this.handleDeleteClick}>
      {formatMessage("Delete")}
    </Button>;
  }

  renderSaveButton () {
    return <Button
      variant="primary"
      margin="0 0 0 x-small"
      disabled={!this.isValid()}
      onClick={this.handleSave}
    >
        {formatMessage("Save")}
    </Button>;
  }

  renderTitleInput () {
    const value = this.findCurrentValue('title');
    return (
      <TextInput
        label={formatMessage("Title")}
        value={value}
        messages={this.state.titleMessages}
        onChange={this.handleTitleChange}
      />
    );
  }

  renderDateInput () {
    const datevalue = this.state.updates.date && this.state.updates.date.isValid() ? this.state.updates.date.toISOString() : undefined;
    return (
      <DateTimeInput
        required={true}
        description={<ScreenReaderContent>{formatMessage("The date and time this to do is due")}</ScreenReaderContent>}
        messages={this.state.dateMessages}
        dateLabel={formatMessage("Date")}
        dateNextLabel={formatMessage("Next Month")}
        datePreviousLabel={formatMessage("Previous Month")}
        timeLabel={formatMessage("Time")}
        timeStep={30}
        locale={this.props.locale}
        timezone={this.props.timeZone}
        value={datevalue}
        layout="stacked"
        onChange={this.handleDateChange}
        invalidDateTimeMessage={this.onInvalidDateTimeMessage}
      />
    );
  }



  renderCourseSelect () {
    const noneOption = {
      value: "none",
      label: formatMessage("Optional: Add Course")
    }
    const courseOptions = (this.props.courses || []).map(course => ({
      value: course.id,
      label: course.longName
    }))

    const courseId = this.findCurrentValue('courseId');
    const selectedOption = courseId
      ? courseOptions.find(o => o.value === courseId)
      : noneOption

    return (
      <Select
        label={formatMessage("Course")}
        selectedOption={selectedOption}
        onChange={this.handleCourseIdChange}
      >
        {[noneOption, ...courseOptions].map(props => (
          <option key={props.value} value={props.value}>{props.label}</option>
        ))}
      </Select>
    );
  }

  renderDetailsInput () {
    const value = this.findCurrentValue('details');
    return (
      <TextArea
        label={formatMessage("Details")}
        height="10rem"
        autoGrow={false}
        value={value}
        onChange={(e) => this.handleChange('details', e.target.value)}
      />
    );
  }

  renderTrayHeader () {
    if (this.editingExistingNote()) {
      return (
        <h2>{formatMessage('Edit {title}', { title: this.props.noteItem.title })}</h2>
      );
    } else {
      return (
        <h2>{formatMessage("Add To Do")}</h2>
      );
    }
  }

  render () {
    return (
      <div className={styles.root}>
        <View
          as="div"
          padding="large medium medium"
        >
          <FormFieldGroup
            rowSpacing="small"
            description={
              <ScreenReaderContent>
                {this.renderTrayHeader()}
              </ScreenReaderContent>
            }
          >
            {this.renderTitleInput()}
            {this.renderDateInput()}
            {this.renderCourseSelect()}
            {this.renderDetailsInput()}
          </FormFieldGroup>
          <View as="div" margin="small 0 0" textAlign="end">
            {this.renderDeleteButton()}
            {this.renderSaveButton()}
          </View>
        </View>
      </div>
    );
  }
}

export default themeable(theme, styles)(UpdateItemTray);
