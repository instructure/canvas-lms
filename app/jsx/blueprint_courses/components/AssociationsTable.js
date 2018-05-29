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
import 'compiled/jquery.rails_flash_notifications'

import Text from '@instructure/ui-elements/lib/components/Text'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import Table from '@instructure/ui-elements/lib/components/Table'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import RemoveIcon from '@instructure/ui-icons/lib/Solid/IconX'

import propTypes from '../propTypes'
import FocusManager from '../focusManager'

const { func, arrayOf, string, bool, instanceOf } = PropTypes

export default class AssociationsTable extends React.Component {
  static propTypes = {
    existingAssociations: propTypes.courseList.isRequired,
    addedAssociations: propTypes.courseList.isRequired,
    removedAssociations: propTypes.courseList.isRequired,
    onRemoveAssociations: func.isRequired,
    onRestoreAssociations: func.isRequired,
    isLoadingAssociations: bool.isRequired,
    focusManager: instanceOf(FocusManager).isRequired,
  }

  static defaultProps = {
    handleFocusLoss: () => {},
  }

  constructor (props) {
    super(props)
    this.state = {
      visibleExisting: props.existingAssociations,
    }
  }

  componentDidMount () {
    this.fixIcons()
  }

  componentWillReceiveProps (nextProps) {
    const removedIds = nextProps.removedAssociations.map(course => course.id)
    this.setState({
      visibleExisting: nextProps.existingAssociations.filter(assoc => !removedIds.includes(assoc.id)),
    })

    if (!this.props.isLoadingAssociations && nextProps.isLoadingAssociations) {
      $.screenReaderFlashMessage(I18n.t('Loading associations started'))
    }

    if (this.props.isLoadingAssociations && !nextProps.isLoadingAssociations) {
      $.screenReaderFlashMessageExclusive(I18n.t('Loading associations complete'))
    }
  }

  componentDidUpdate () {
    this.fixIcons()
  }

  onRemove = (e) => {
    e.preventDefault()

    const form = e.currentTarget
    const courseId = form.getAttribute('data-course-id')
    const courseName = form.getAttribute('data-course-name')
    const focusIndex = form.getAttribute('data-focus-index')

    setTimeout(() => this.props.focusManager.movePrev(focusIndex), 400)

    $.screenReaderFlashMessage(I18n.t('Removed course association %{course}', { course: courseName }))
    this.props.onRemoveAssociations([courseId])
  }

  onRestore = (e) => {
    e.preventDefault()

    const form = e.currentTarget
    const courseId = form.getAttribute('data-course-id')
    const courseName = form.getAttribute('data-course-name')

    // re-focus the restored association
    setTimeout(() => document.querySelector(`.bca-associations-table form[data-course-id="${courseId}"] button[type="submit"]`).focus(), 400)

    $.screenReaderFlashMessage(I18n.t('Restored course association %{course}', { course: courseName }))
    this.props.onRestoreAssociations([courseId])
  }

  // in IE, instui icons are in the tab order and get focus, even if hidden
  // this fixes them up so that doesn't happen.
  // Eventually this should get folded into instui via INSTUI-572
  fixIcons () {
    if (this.wrapper) {
      Array.prototype.forEach.call(
        this.wrapper.querySelectorAll('svg[aria-hidden]'),
        (el) => { el.setAttribute('focusable', 'false') }
      )
    }
  }
  renderColGroup () {
    return (
      <colgroup>
        <col span="1" style={{width: '32%'}} />
        <col span="1" style={{width: '15%'}} />
        <col span="1" style={{width: '15%'}} />
        <col span="1" style={{width: '10%'}} />
        <col span="1" style={{width: '25%'}} />
        <col span="1" style={{width: '3%'}} />
      </colgroup>
    )
  }

  renderHeaders () {
    return (
      <tr>
        <th scope="col">{I18n.t('Title')}</th>
        <th scope="col">{I18n.t('Short Name')}</th>
        <th scope="col">{I18n.t('Term')}</th>
        <th scope="col">{I18n.t('SIS ID')}</th>
        <th scope="col">{I18n.t('Teacher(s)')}</th>
        <th scope="col">
          <ScreenReaderContent>{I18n.t('Remove Association')}</ScreenReaderContent>
        </th>
      </tr>
    )
  }

  renderCellText (text) {
    return <Text color="secondary" size="small">{text}</Text>
  }

  renderRows (associations) {
    return associations.map((course) => {
      const focusNode = this.props.focusManager.allocateNext()
      const label = I18n.t('Remove course association %{name}', { name: course.name })

      return (
        <tr id={`course_${course.id}`} key={course.id} className="bca-associations__course-row">
          <td>{this.renderCellText(course.name)}</td>
          <td>{this.renderCellText(course.course_code)}</td>
          <td>{this.renderCellText(course.term.name)}</td>
          <td>{this.renderCellText(course.sis_course_id)}</td>
          <td>
            {this.renderCellText(course.teachers.map(teacher => teacher.display_name).join(', '))}
          </td>
          <td className="bca-associations__x-col">
            <form
              onSubmit={this.onRemove}
              data-course-id={course.id}
              data-course-name={course.name}
              data-focus-index={focusNode.index}
            >
              <Button
                type="submit"
                size="small"
                variant="icon"
                ref={focusNode.ref}
                aria-label={label}
              >
                <RemoveIcon />
                <ScreenReaderContent>{label}</ScreenReaderContent>
              </Button>
            </form>
          </td>
        </tr>
      )
    })
  }

  renderToBeRemovedRows (associations) {
    return associations.map((course) => {
      const focusNode = this.props.focusManager.allocateNext()
      const label = I18n.t('Undo remove course association %{name}', { name: course.name })

      return (
        <tr key={course.id} className="bca-associations__course-row">
          <td>{this.renderCellText(course.name)}</td>
          <td>{this.renderCellText(course.course_code)}</td>
          <td>{this.renderCellText(course.term.name)}</td>
          <td>{this.renderCellText(course.sis_course_id)}</td>
          <td>
            {this.renderCellText(course.teachers.map(teacher => teacher.display_name).join(', '))}
          </td>
          <td className="bca-associations__x-col">
            <form
              onSubmit={this.onRestore}
              data-course-id={course.id}
              data-course-name={course.name}
              data-focus-index={focusNode.index}
            >
              <Button
                type="submit"
                size="small"
                ref={focusNode.ref}
                aria-label={label}
              >
                <PresentationContent>{I18n.t('Undo')}</PresentationContent>
                <ScreenReaderContent>{label}</ScreenReaderContent>
              </Button>
            </form>
          </td>
        </tr>
      )
    })
  }

  renderExistingAssociations () {
    if (this.state.visibleExisting.length) {
      return [(
        <tr key="existing-heading">
          <th scsope="rowgroup" colSpan={6}><Text weight="bold" size="small">{I18n.t('Current')}</Text></th>
        </tr>
      )].concat(this.renderRows(this.state.visibleExisting))
    }

    return null
  }

  renderAddedAssociations () {
    if (this.props.addedAssociations.length) {
      return [(
        <tr key="added-heading">
          <th scsope="rowgroup" colSpan={6}><Text weight="bold" size="small">{I18n.t('To be Added')}</Text></th>
        </tr>
      )].concat(this.renderRows(this.props.addedAssociations))
    }

    return null
  }

  renderRemovedAssociations () {
    if (this.props.removedAssociations.length) {
      return [(
        <tr key="removed-heading">
          <th scsope="rowgroup" colSpan={6}><Text weight="bold" size="small">{I18n.t('To be Removed')}</Text></th>
        </tr>
      )].concat(this.renderToBeRemovedRows(this.props.removedAssociations))
    }

    return null
  }

  renderTable () {
    return (
      <Table caption={<ScreenReaderContent>{I18n.t('Blueprint Course Associations')}</ScreenReaderContent>}>
        {this.renderColGroup()}
        <thead>
          {this.renderHeaders()}
        </thead>
        <tbody>
          {this.renderExistingAssociations()}
        </tbody>
        <tbody>
          {this.renderAddedAssociations()}
        </tbody>
        <tbody>
          {this.renderRemovedAssociations()}
        </tbody>
      </Table>
    )
  }

  renderLoadingOverlay () {
    const { isLoadingAssociations } = this.props
    if (isLoadingAssociations) {
      const title = I18n.t('Loading Associations')
      return (
        <div className="bca__overlay">
          <Spinner title={title} />
          <Text as="p">{title}</Text>
        </div>
      )
    }

    return null
  }

  render () {
    const { addedAssociations, removedAssociations } = this.props
    this.props.focusManager.reset()
    return (
      <div
        className="bca-associations-table"
        ref={(c) => { this.wrapper = c }}
      >
        {this.renderLoadingOverlay()}
        { this.state.visibleExisting.length || addedAssociations.length || removedAssociations.length
          ? this.renderTable()
          : <Text color="secondary" as="p">{I18n.t('There are currently no associated courses.')}</Text>
        }
      </div>
    )
  }
}
