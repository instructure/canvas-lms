import I18n from 'i18n!blueprint_config'
import $ from 'jquery'
import React from 'react'
import Typography from 'instructure-ui/Typography'
import ScreenReaderContent from 'instructure-ui/ScreenReaderContent'
import PresentationContent from 'instructure-ui/PresentationContent'
import Table from 'instructure-ui/Table'
import Checkbox from 'instructure-ui/Checkbox'
import 'compiled/jquery.rails_flash_notifications'

import propTypes from '../propTypes'

export default class CoursePickerTable extends React.Component {
  static propTypes = {
    courses: propTypes.courseList.isRequired,
    onSelectedChanged: React.PropTypes.func,
  }

  static defaultProps = {
    onSelectedChanged: () => {},
  }

  constructor (props) {
    super(props)
    this.state = {
      selected: {},
      selectedAll: false,
    }
  }

  componentWillReceiveProps (nextProps) {
    // remove selected state for courses that are removed from props
    const courseIds = nextProps.courses.map(course => course.id)
    this.setState({
      selectedAll: false,
      selected: Object.keys(this.state.selected)
        .filter(id => courseIds.includes(id))
        .reduce((selected, id) => Object.assign(selected, { [id]: this.state.selected[id] }), {}),
    })
  }

  onSelectToggle = (e) => {
    const selected = this.state.selected
    selected[e.target.value] = e.target.checked
    const index = this.props.courses.findIndex(c => c.id === e.target.value)
    const course = this.props.courses[index]
    const srMsg = e.target.checked
                ? I18n.t('Selected course %{course}', { course: course.name })
                : I18n.t('Unselected course %{course}', { course: course.name })
    $.screenReaderFlashMessage(srMsg)
    this.setState({ selected, selectedAll: false }, () => {
      this.props.onSelectedChanged(this.state.selected)
    })

    setTimeout(() => {
      this.handleFocusLoss(index)
    }, 0)
  }

  onSelectAllToggle = (e) => {
    const srMsg = e.target.checked
                ? I18n.t('Selected all courses')
                : I18n.t('Unselected all courses')
    $.screenReaderFlashMessage(srMsg)
    this.setState({
      selectedAll: e.target.checked,
      selected: e.target.checked ? this.props.courses
                  .reduce((selected, course) =>
                    Object.assign(selected, { [course.id]: true })
                  , {}) : {}
    }, () => {
      this.props.onSelectedChanged(this.state.selected)
    })
  }

  handleFocusLoss (index) {
    if (this.props.courses.length === 0) {
      this.selectAllCheckbox.focus()
    } else if (index >= this.props.courses.length) {
      this.handleFocusLoss(index - 1)
    } else {
      this.tableBody.querySelectorAll('.bps-table__course-row input[type="checkbox"]')[index].focus()
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
    return <Typography color="secondary" size="small">{text}</Typography>
  }

  renderRows () {
    return this.props.courses.map((course, index) =>
      <tr key={course.id} className="bps-table__course-row">
        <td>
          <Checkbox
            onChange={this.onSelectToggle}
            value={course.id}
            checked={this.state.selected[course.id]}
            label={
              <ScreenReaderContent>
                {I18n.t('Toggle select course %{name}', { name: course.name })}
              </ScreenReaderContent>
            }
          />
        </td>
        <td>{this.renderCellText(course.name)}</td>
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
      <tr key="no-results" className="bps-table__no-results">
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
            <thead className="bps-table__head">
              {this.renderHeaders()}
            </thead>
            <tbody />
          </Table>
        </PresentationContent>
        <p className="bps-table__select-all">
          <Checkbox
            onChange={this.onSelectAllToggle}
            value="all"
            checked={this.state.selectedAll}
            ref={(c) => { this.selectAllCheckbox = c }}
            label={
              <Typography size="small">
                {I18n.t({ one: 'Select (%{count}) Course', other: 'Select All (%{count}) Courses' },
                { count: this.props.courses.length })}
              </Typography>
            }
          />
        </p>
      </div>
    )
  }

  render () {
    return (
      <div className="bps-table__wrapper">
        {this.renderStickyHeaders()}
        <div className="bps-table__content-wrapper">
          <Table caption={<ScreenReaderContent>{I18n.t('Blueprint Courses')}</ScreenReaderContent>}>
            {this.renderColGroup()}
            {/* on the real table, we'll include the headers again, but make them screen reader only */}
            <ScreenReaderContent as="thead">
              {this.renderHeaders()}
            </ScreenReaderContent>
            <tbody className="bps-table__body" ref={(c) => { this.tableBody = c }}>
              {this.renderBodyContent()}
            </tbody>
          </Table>
        </div>
      </div>
    )
  }
}
