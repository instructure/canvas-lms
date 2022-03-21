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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import '@canvas/rails-flash-notifications'

import {Text} from '@instructure/ui-text'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {CondensedButton} from '@instructure/ui-buttons'
import {IconXSolid} from '@instructure/ui-icons'

import propTypes from '@canvas/blueprint-courses/react/propTypes'
import FocusManager from '../focusManager'

const I18n = useI18nScope('blueprint_settingsAssociationsTable')

const {func, bool, instanceOf} = PropTypes

export default class AssociationsTable extends React.Component {
  static propTypes = {
    existingAssociations: propTypes.courseList.isRequired,
    addedAssociations: propTypes.courseList.isRequired,
    removedAssociations: propTypes.courseList.isRequired,
    onRemoveAssociations: func.isRequired,
    onRestoreAssociations: func.isRequired,
    isLoadingAssociations: bool.isRequired,
    focusManager: instanceOf(FocusManager).isRequired
  }

  constructor(props) {
    super(props)
    this.wrapper = React.createRef()
    this.state = {
      visibleExisting: props.existingAssociations
    }
  }

  componentDidMount() {
    this.fixIcons()
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    const removedIds = nextProps.removedAssociations.map(course => course.id)
    this.setState({
      visibleExisting: nextProps.existingAssociations.filter(
        assoc => !removedIds.includes(assoc.id)
      )
    })

    if (!this.props.isLoadingAssociations && nextProps.isLoadingAssociations) {
      $.screenReaderFlashMessage(I18n.t('Loading associations started'))
    }

    if (this.props.isLoadingAssociations && !nextProps.isLoadingAssociations) {
      $.screenReaderFlashMessageExclusive(I18n.t('Loading associations complete'))
    }
  }

  componentDidUpdate() {
    this.fixIcons()
  }

  onRemove = e => {
    e.preventDefault()

    const form = e.currentTarget
    const courseId = form.getAttribute('data-course-id')
    const courseName = form.getAttribute('data-course-name')
    const focusIndex = form.getAttribute('data-focus-index')

    setTimeout(() => this.props.focusManager.movePrev(focusIndex), 400)

    $.screenReaderFlashMessage(I18n.t('Removed course association %{course}', {course: courseName}))
    this.props.onRemoveAssociations([courseId])
  }

  onRestore = e => {
    e.preventDefault()

    const form = e.currentTarget
    const courseId = form.getAttribute('data-course-id')
    const courseName = form.getAttribute('data-course-name')

    // re-focus the restored association
    setTimeout(
      () =>
        document
          .querySelector(
            `.bca-associations-table form[data-course-id="${courseId}"] button[type="submit"]`
          )
          .focus(),
      400
    )

    $.screenReaderFlashMessage(
      I18n.t('Restored course association %{course}', {course: courseName})
    )
    this.props.onRestoreAssociations([courseId])
  }

  // in IE, instui icons are in the tab order and get focus, even if hidden
  // this fixes them up so that doesn't happen.
  // Eventually this should get folded into instui via INSTUI-572
  fixIcons() {
    const wrapper = this.wrapper.current
    if (wrapper) {
      Array.prototype.forEach.call(wrapper.querySelectorAll('svg[aria-hidden]'), el => {
        el.setAttribute('focusable', 'false')
      })
    }
  }

  renderHeaders() {
    return (
      <Table.Row>
        <Table.ColHeader id="colheader-title" width="32%">
          {I18n.t('Title')}
        </Table.ColHeader>
        <Table.ColHeader id="colheader-shortname" width="15%">
          {I18n.t('Short Name')}
        </Table.ColHeader>
        <Table.ColHeader id="colheader-term" width="15%">
          {I18n.t('Term')}
        </Table.ColHeader>
        <Table.ColHeader id="colheader-sisid" width="10%">
          {I18n.t('SIS ID')}
        </Table.ColHeader>
        <Table.ColHeader id="colheader-teachers" width="25%">
          {I18n.t('Teacher(s)')}
        </Table.ColHeader>
        <Table.ColHeader id="colheader-remove" width="3%">
          <ScreenReaderContent>{I18n.t('Remove Association')}</ScreenReaderContent>
        </Table.ColHeader>
      </Table.Row>
    )
  }

  renderCellText(text) {
    return (
      <Text color="secondary" size="small">
        {text}
      </Text>
    )
  }

  renderRows(associations) {
    return associations.map(course => {
      const focusNode = this.props.focusManager.allocateNext()
      const label = I18n.t('Remove course association %{name}', {name: course.name})

      return (
        <Table.Row id={`course_${course.id}`} key={course.id} data-testid="associations-course-row">
          <Table.Cell>{this.renderCellText(course.name)}</Table.Cell>
          <Table.Cell>{this.renderCellText(course.course_code)}</Table.Cell>
          <Table.Cell>{this.renderCellText(course.term.name)}</Table.Cell>
          <Table.Cell>{this.renderCellText(course.sis_course_id)}</Table.Cell>
          <Table.Cell>
            {this.renderCellText(
              course.teachers
                ? course.teachers.map(teacher => teacher.display_name).join(', ')
                : I18n.t('%{teacher_count} teachers', {teacher_count: course.teacher_count})
            )}
          </Table.Cell>
          <Table.Cell>
            <form
              style={{margin: 0}}
              onSubmit={this.onRemove}
              data-course-id={course.id}
              data-course-name={course.name}
              data-focus-index={focusNode.index}
            >
              <CondensedButton
                type="submit"
                size="small"
                renderIcon={<IconXSolid />}
                ref={focusNode.ref}
                aria-label={label}
              >
                <ScreenReaderContent>{label}</ScreenReaderContent>
              </CondensedButton>
            </form>
          </Table.Cell>
        </Table.Row>
      )
    })
  }

  renderToBeRemovedRows(associations) {
    return associations.map(course => {
      const focusNode = this.props.focusManager.allocateNext()
      const label = I18n.t('Undo remove course association %{name}', {name: course.name})

      return (
        <Table.Row key={course.id} data-testid="associations-course-row">
          <Table.Cell>{this.renderCellText(course.name)}</Table.Cell>
          <Table.Cell>{this.renderCellText(course.course_code)}</Table.Cell>
          <Table.Cell>{this.renderCellText(course.term.name)}</Table.Cell>
          <Table.Cell>{this.renderCellText(course.sis_course_id)}</Table.Cell>
          <Table.Cell>
            {this.renderCellText(
              course.teachers
                ? course.teachers.map(teacher => teacher.display_name).join(', ')
                : I18n.t('%{teacher_count} teachers', {teacher_count: course.teacher_count})
            )}
          </Table.Cell>
          <Table.Cell>
            <form
              style={{margin: 0}}
              onSubmit={this.onRestore}
              data-course-id={course.id}
              data-course-name={course.name}
              data-focus-index={focusNode.index}
            >
              <CondensedButton
                type="submit"
                size="small"
                margin="x-small 0"
                ref={focusNode.ref}
                aria-label={label}
              >
                <PresentationContent>{I18n.t('Undo')}</PresentationContent>
                <ScreenReaderContent>{label}</ScreenReaderContent>
              </CondensedButton>
            </form>
          </Table.Cell>
        </Table.Row>
      )
    })
  }

  renderExistingAssociations() {
    if (this.state.visibleExisting.length) {
      return [
        <Table.Row key="existing-heading">
          <Table.ColHeader id="existing-current" colSpan={6}>
            <Text weight="bold" size="small">
              {I18n.t('Current')}
            </Text>
          </Table.ColHeader>
        </Table.Row>
      ].concat(this.renderRows(this.state.visibleExisting))
    }

    return null
  }

  renderAddedAssociations() {
    if (this.props.addedAssociations.length) {
      return [
        <Table.Row key="added-heading">
          <Table.ColHeader id="added-to-be-added" colSpan={6}>
            <Text weight="bold" size="small">
              {I18n.t('To be Added')}
            </Text>
          </Table.ColHeader>
        </Table.Row>
      ].concat(this.renderRows(this.props.addedAssociations))
    }

    return null
  }

  renderRemovedAssociations() {
    if (this.props.removedAssociations.length) {
      return [
        <Table.Row key="removed-heading">
          <Table.ColHeader id="removed-to-be-removed" colSpan={6}>
            <Text weight="bold" size="small">
              {I18n.t('To be Removed')}
            </Text>
          </Table.ColHeader>
        </Table.Row>
      ].concat(this.renderToBeRemovedRows(this.props.removedAssociations))
    }

    return null
  }

  renderTable() {
    return (
      <Table caption={I18n.t('Blueprint Course Associations')}>
        <Table.Head>{this.renderHeaders()}</Table.Head>
        <Table.Body>{this.renderExistingAssociations()}</Table.Body>
        <Table.Body>{this.renderAddedAssociations()}</Table.Body>
        <Table.Body>{this.renderRemovedAssociations()}</Table.Body>
      </Table>
    )
  }

  renderLoadingOverlay() {
    const {isLoadingAssociations} = this.props
    if (isLoadingAssociations) {
      const title = I18n.t('Loading Associations')
      return (
        <div className="bca__overlay">
          <Spinner renderTitle={title} />
          <Text as="p">{title}</Text>
        </div>
      )
    }

    return null
  }

  render() {
    const {addedAssociations, removedAssociations} = this.props
    this.props.focusManager.reset()
    return (
      <div className="bca-associations-table" ref={this.wrapper}>
        {this.renderLoadingOverlay()}
        {this.state.visibleExisting.length ||
        addedAssociations.length ||
        removedAssociations.length ? (
          this.renderTable()
        ) : (
          <Text color="secondary" as="p">
            {I18n.t('There are currently no associated courses.')}
          </Text>
        )}
      </div>
    )
  }
}
