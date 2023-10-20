/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import React, {Component} from 'react'
import _ from 'lodash'
import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import PropTypes from 'prop-types'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import moment from 'moment-timezone'
import {useScope as useI18nScope} from '@canvas/i18n'

import {courseShape} from '../plannerPropTypes'
import buildStyle from './style'

const I18n = useI18nScope('planner')

export class UpdateItemTray_ extends Component {
  static propTypes = {
    courses: PropTypes.arrayOf(PropTypes.shape(courseShape)).isRequired,
    noteItem: PropTypes.object,
    onSavePlannerItem: PropTypes.func.isRequired,
    onDeletePlannerItem: PropTypes.func.isRequired,
    locale: PropTypes.string.isRequired,
    timeZone: PropTypes.string.isRequired,
  }

  constructor(props) {
    super(props)
    const updates = this.getNoteUpdates(props)
    this.state = {
      updates,
      titleMessages: [],
      dateMessages: [],
    }
    this.style = buildStyle()
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    if (!_.isEqual(this.props.noteItem, nextProps.noteItem)) {
      const updates = this.getNoteUpdates(nextProps)
      this.setState({updates}, this.updateMessages)
    }
  }

  editingExistingNote() {
    return this.props.noteItem && this.props.noteItem.uniqueId
  }

  getNoteUpdates(props) {
    const updates = _.cloneDeep(props.noteItem) || {}
    if (updates.context) {
      updates.courseId = updates.context.id
      delete updates.context
    }
    if (!updates.date) {
      updates.date = moment.tz(props.timeZone).endOf('day')
    }
    return updates
  }

  updateMessages = () => {
    if (!this.state.updates.date) {
      this.setState({dateMessages: [{type: 'error', text: I18n.t('Date is required')}]})
    } else {
      this.setState({dateMessages: []})
    }
  }

  handleSave = () => {
    const updates = {...this.state.updates}
    if (updates.courseId) {
      updates.context = {id: updates.courseId}
    } else {
      updates.context = {id: null}
    }
    updates.date = updates.date.toISOString()
    delete updates.courseId
    this.props.onSavePlannerItem(updates)
  }

  handleChange = (field, value) => {
    this.setState(state => ({updates: {...state.updates, [field]: value}}), this.updateMessages)
  }

  handleCourseIdChange = (e, {value}) => {
    if (!value) return
    if (value === 'none') value = undefined
    this.handleChange('courseId', value)
  }

  handleTitleChange = e => {
    const value = e.target.value
    if (value === '') {
      this.setState({
        titleMessages: [{type: 'error', text: I18n.t('title is required')}],
      })
    } else {
      this.setState({titleMessages: []})
    }
    this.handleChange('title', value)
  }

  handleDateChange = (e, isoDate) => {
    const value = isoDate || ''
    this.handleChange('date', moment.tz(value, this.props.timeZone))
  }

  invalidDateTimeMessage(rawDateValue, _rawTimeValue) {
    let errmsg
    if (rawDateValue) {
      errmsg = I18n.t('#{date} is not a valid date.', {date: rawDateValue})
    } else {
      errmsg = I18n.t('You must provide a date and time.')
    }
    return errmsg
  }

  // separating the function from the bound callback is necessary so I can spy
  // on invalidDateTimeMessage in unit tests.
  onInvalidDateTimeMessage = this.invalidDateTimeMessage.bind(this)

  handleDeleteClick = () => {
    // eslint-disable-next-line no-restricted-globals, no-alert
    if (confirm(I18n.t('Are you sure you want to delete this planner item?'))) {
      this.props.onDeletePlannerItem(this.props.noteItem)
    }
  }

  findCurrentValue(field) {
    return this.state.updates[field] || ''
  }

  isValid() {
    if (this.state.updates.title && this.state.updates.date && this.state.updates.date.isValid()) {
      return this.state.updates.title.replace(/\s/g, '').length > 0
    }
    return false
  }

  renderDeleteButton() {
    if (!this.editingExistingNote()) return
    return (
      <Button
        data-testid="delete"
        color="primary-inverse"
        margin="0 x-small 0 0"
        onClick={this.handleDeleteClick}
      >
        {I18n.t('Delete')}
      </Button>
    )
  }

  renderSaveButton() {
    return (
      <Button
        data-testid="save"
        color="primary"
        margin="0 0 0 x-small"
        interaction={this.isValid() ? 'enabled' : 'disabled'}
        onClick={this.handleSave}
      >
        {I18n.t('Save')}
      </Button>
    )
  }

  renderTitleInput() {
    const value = this.findCurrentValue('title')
    return (
      <TextInput
        data-testid="title"
        renderLabel={() => I18n.t('Title')}
        value={value}
        messages={this.state.titleMessages}
        onChange={this.handleTitleChange}
      />
    )
  }

  renderDateInput() {
    const datevalue =
      this.state.updates.date && this.state.updates.date.isValid()
        ? this.state.updates.date.toISOString()
        : undefined
    return (
      <DateTimeInput
        required={true}
        description={
          <ScreenReaderContent>{I18n.t('The date and time this to do is due')}</ScreenReaderContent>
        }
        messages={this.state.dateMessages}
        dateRenderLabel={I18n.t('Date')}
        nextMonthLabel={I18n.t('Next Month')}
        prevMonthLabel={I18n.t('Previous Month')}
        timeRenderLabel={I18n.t('Time')}
        timeStep={30}
        locale={this.props.locale}
        timezone={this.props.timeZone}
        value={datevalue}
        layout="stacked"
        onChange={this.handleDateChange}
        invalidDateTimeMessage={this.onInvalidDateTimeMessage}
        allowNonStepInput={true}
      />
    )
  }

  renderCourseSelect() {
    const noneOption = {
      value: 'none',
      label: I18n.t('Optional: Add Course'),
    }
    const courseOptions = (this.props.courses || [])
      .filter(course => course.enrollmentType === 'StudentEnrollment' || course.is_student)
      .map(course => ({
        value: course.id,
        label: course.longName || course.long_name,
      }))

    const courseId = this.findCurrentValue('courseId')
    const selectedOption = courseId ? courseOptions.find(o => o.value === courseId) : noneOption

    return (
      <SimpleSelect
        renderLabel={I18n.t('Course')}
        assistiveText={I18n.t('Use arrow keys to navigate options.')}
        id="to-do-item-course-select"
        value={selectedOption.value}
        onChange={this.handleCourseIdChange}
      >
        {[noneOption, ...courseOptions].map(props => (
          <SimpleSelect.Option key={props.value} id={props.value} value={props.value}>
            {props.label}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    )
  }

  renderDetailsInput() {
    const value = this.findCurrentValue('details')
    return (
      <TextArea
        data-testid="details"
        label={I18n.t('Details')}
        height="10rem"
        autoGrow={false}
        value={value}
        onChange={e => this.handleChange('details', e.target.value)}
      />
    )
  }

  renderTrayHeader() {
    if (this.editingExistingNote()) {
      return <h2>{I18n.t('Edit %{title}', {title: this.props.noteItem.title})}</h2>
    } else {
      return <h2>{I18n.t('Add To Do')}</h2>
    }
  }

  render = () => (
    <>
      <style>{this.style.css}</style>
      <div className={this.style.classNames.root}>
        <View as="div" padding="large medium medium">
          <FormFieldGroup
            rowSpacing="small"
            description={<ScreenReaderContent>{this.renderTrayHeader()}</ScreenReaderContent>}
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
    </>
  )
}

export default UpdateItemTray_
