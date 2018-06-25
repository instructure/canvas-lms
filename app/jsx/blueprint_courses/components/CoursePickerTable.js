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

import I18n from 'i18n!blueprint_settings'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import Text from '@instructure/ui-elements/lib/components/Text'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import Table from '@instructure/ui-elements/lib/components/Table'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import 'compiled/jquery.rails_flash_notifications'

import propTypes from '../propTypes'

const { arrayOf, string } = PropTypes

export default class CoursePickerTable extends React.Component {
  static propTypes = {
    courses: propTypes.courseList.isRequired,
    selectedCourses: arrayOf(string).isRequired,
    onSelectedChanged: PropTypes.func,
  }

  static defaultProps = {
    onSelectedChanged: () => {},
  }

  constructor (props) {
    super(props)
    this.state = {
      selected: this.parseSelectedCourses(props.selectedCourses),
      selectedAll: false,
    }
    this._tableRef = null;
  }

  componentDidMount () {
    this.fixIcons()
  }

  componentWillReceiveProps (nextProps) {
    this.setState({
      selected: this.parseSelectedCourses(nextProps.selectedCourses),
      selectedAll: nextProps.selectedCourses.length === nextProps.courses.length,
    })
  }

  componentDidUpdate () {
    this.fixIcons()
  }

  onSelectToggle = (e) => {
    const index = this.props.courses.findIndex(c => c.id === e.target.value)
    const course = this.props.courses[index]
    const srMsg = e.target.checked
                ? I18n.t('Selected course %{course}', { course: course.name })
                : I18n.t('Unselected course %{course}', { course: course.name })
    $.screenReaderFlashMessage(srMsg)

    this.updateSelected({ [e.target.value]: e.target.checked }, false)

    setTimeout(() => {
      this.handleFocusLoss(index)
    }, 0)
  }

  onSelectAllToggle = (e) => {
    $.screenReaderFlashMessage(e.target.checked
      ? I18n.t('Selected all courses')
      : I18n.t('Unselected all courses'))

    const selected = this.props.courses.reduce((selectedMap, course) => {
      selectedMap[course.id] = e.target.checked // eslint-disable-line
      return selectedMap
    }, {})
    this.updateSelected(selected, e.target.checked)
  }

  // in IE, instui icons are in the tab order and get focus, even if hidden
  // this fixes them up so that doesn't happen.
  // Eventually this should get folded into instui via INSTUI-572
  fixIcons () {
    if (this._tableRef) {
      Array.prototype.forEach.call(
        this._tableRef.querySelectorAll('svg[aria-hidden]'),
        (el) => { el.setAttribute('focusable', 'false') }
      )
    }
  }

  parseSelectedCourses (courses = []) {
    return courses.reduce((selected, courseId) => {
      selected[courseId] = true // eslint-disable-line
      return selected
    }, {})
  }

  updateSelected (selectedDiff, selectedAll) {
    const oldSelected = this.state.selected
    const added = []
    const removed = []

    this.props.courses.forEach(({ id }) => {
      if (oldSelected[id] === true && selectedDiff[id] === false) removed.push(id)
      if (oldSelected[id] !== true && selectedDiff[id] === true) added.push(id)
    })

    this.props.onSelectedChanged({ added, removed })
    this.setState({ selectedAll })
  }

  handleFocusLoss (index) {
    if (this.props.courses.length === 0) {
      this.selectAllCheckbox.focus()
    } else if (index >= this.props.courses.length) {
      this.handleFocusLoss(index - 1)
    } else {
      this.tableBody.querySelectorAll('.bca-table__course-row input[type="checkbox"]')[index].focus()
    }
  }

  renderColGroup () {
    return (
      <colgroup>
        <col span="1" style={{width: '3%'}} />
        <col span="1" style={{width: '32%'}} />
        <col span="1" style={{width: '15%'}} />
        <col span="1" style={{width: '15%'}} />
        <col span="1" style={{width: '10%'}} />
        <col span="1" style={{width: '25%'}} />
      </colgroup>
    )
  }

  renderHeaders () {
    return (
      <tr>
        <th scope="col">
          <ScreenReaderContent>{I18n.t('Course Selection')}</ScreenReaderContent>
        </th>
        <th scope="col">{I18n.t('Title')}</th>
        <th scope="col">{I18n.t('Short Name')}</th>
        <th scope="col">{I18n.t('Term')}</th>
        <th scope="col">{I18n.t('SIS ID')}</th>
        <th scope="col">{I18n.t('Teacher(s)')}</th>
      </tr>
    )
  }

  renderCellText (text) {
    return <Text color="secondary" size="small">{text}</Text>
  }

  renderRows () {
    return this.props.courses.map(course =>
      <tr id={`course_${course.id}`} key={course.id} className="bca-table__course-row">
        <td>
          <Checkbox
            onChange={this.onSelectToggle}
            value={course.id}
            checked={this.state.selected[course.id] === true}
            label={
              <ScreenReaderContent>
                {I18n.t('Toggle select course %{name}', { name: course.original_name || course.name })}
              </ScreenReaderContent>
            }
          />
        </td>
        <td>{this.renderCellText(course.original_name || course.name)}</td>
        <td>{this.renderCellText(course.course_code)}</td>
        <td>{this.renderCellText(course.term.name)}</td>
        <td>{this.renderCellText(course.sis_course_id)}</td>
        <td>
          {this.renderCellText(course.teachers.map(teacher => teacher.display_name).join(', '))}
        </td>
      </tr>
    )
  }

  renderBodyContent () {
    if (this.props.courses.length > 0) {
      return this.renderRows()
    }

    return (
      <tr key="no-results" className="bca-table__no-results">
        <td>{this.renderCellText(I18n.t('No results'))}</td>
      </tr>
    )
  }

  renderStickyHeaders () {
    // in order to create a sticky table header, we'll create a separate table with
    // just the visual sticky headers, that will be hidden from screen readers
    return (
      <div className="btps-table__header-wrapper">
        <PresentationContent as="div">
          <Table caption={<ScreenReaderContent>{I18n.t('Blueprint Courses')}</ScreenReaderContent>}>
            {this.renderColGroup()}
            <thead className="bca-table__head">
              {this.renderHeaders()}
            </thead>
            <tbody />
          </Table>
        </PresentationContent>
        <div className="bca-table__select-all">
          <Checkbox
            onChange={this.onSelectAllToggle}
            value="all"
            checked={this.state.selectedAll}
            ref={(c) => { this.selectAllCheckbox = c }}
            label={
              <Text size="small">
                {I18n.t({ one: 'Select (%{count}) Course', other: 'Select All (%{count}) Courses' },
                { count: this.props.courses.length })}
              </Text>
            }
          />
        </div>
      </div>
    )
  }

  render () {
    return (
      <div className="bca-table__wrapper" ref={(el) => { this._tableRef = el }}>
        {this.renderStickyHeaders()}
        <div className="bca-table__content-wrapper">
          <Table caption={<ScreenReaderContent>{I18n.t('Blueprint Courses')}</ScreenReaderContent>}>
            {this.renderColGroup()}
            {/* on the real table, we'll include the headers again, but make them screen reader only */}
            <ScreenReaderContent as="thead">
              {this.renderHeaders()}
            </ScreenReaderContent>
            <tbody className="bca-table__body" ref={(c) => { this.tableBody = c }}>
              {this.renderBodyContent()}
            </tbody>
          </Table>
        </div>
      </div>
    )
  }
}
