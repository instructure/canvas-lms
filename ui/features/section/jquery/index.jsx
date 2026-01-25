/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import {render, rerender} from '@canvas/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, formErrors */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/util/templateData'
import PaginatedList from './PaginatedList'
import UncrosslistForm from '../react/UncrosslistForm'
import CrosslistForm from '../react/CrosslistForm'
import enrollmentTemplate from '../jst/enrollment.handlebars'
import sectionEnrollmentPresenter from '../sectionEnrollmentPresenter'
import '@canvas/context-cards/react/StudentContextCardTrigger'
import {renderDatetimeField} from '@canvas/datetime/jquery/DatetimeField'
import FormattedErrorMessage from '@canvas/assignments/react/FormattedErrorMessage'
import StartDateTimeInput from '../react/StartDateTimeInput'
import EndDateTimeInput from '../react/EndDateTimeInput'
import {validateDateTime, validateStartDateAfterEnd, START_AT_DATE, END_AT_DATE} from '../utils'
import ready from '@instructure/ready'

const I18n = createI18nScope('section')

ready(() => {
  const section_id = window.location.pathname.split('/')[4],
    $edit_section_form = $('#edit_section_form'),
    $edit_section_link = $('.edit_section_link')
  new PaginatedList($('#current-enrollment-list'), {
    presenter: sectionEnrollmentPresenter,
    template: enrollmentTemplate,
    url: '/api/v1/sections/' + section_id + '/enrollments?include[]=can_be_removed',
  })
  new PaginatedList($('#completed-enrollment-list'), {
    presenter: sectionEnrollmentPresenter,
    requestParams: {state: 'completed', page: 1, per_page: 25},
    template: enrollmentTemplate,
    url: '/api/v1/sections/' + section_id + '/enrollments?include[]=can_be_removed',
  })

  function renderStartAt() {
    const startDateTimeInput = document.getElementById('course_section_start_datetime_input')
    if (startDateTimeInput) {
      const startDateTimeValue = document.getElementById('start_datetime_value')
      let value
      if (startDateTimeValue) {
        value = startDateTimeValue.value
      }
      const onChange = isoDate => {
        startDateTimeValue.value = isoDate ?? ''
      }
      render(
        <StartDateTimeInput
          initialValue={value}
          handleDateTimeChange={onChange}
        ></StartDateTimeInput>,
        startDateTimeInput,
      )
    }
  }

  function renderEndAt() {
    const endDateTimeInput = document.getElementById('course_section_end_datetime_input')
    if (endDateTimeInput) {
      const endDateTimeValue = document.getElementById('end_datetime_value')
      let value
      if (endDateTimeValue) {
        value = endDateTimeValue.value
      }
      const onChange = isoDate => {
        endDateTimeValue.value = isoDate ?? ''
      }
      render(
        <EndDateTimeInput initialValue={value} handleDateTimeChange={onChange}></EndDateTimeInput>,
        endDateTimeInput,
      )
    }
  }

  renderStartAt()
  renderEndAt()

  const errorRoots = {}

  function renderFormErrors(formErrors, shouldFocus = false) {
    formErrors.forEach(formError => {
      let container = $(formError.containerId)
      if (!container.length) container = $(`[name="${formError.containerName}"]`)
      const errorsContainer = $(formError.errorsContainerId)[0]
      if (container) {
        if (!formError.instUIControlled) container.addClass('error-outline')

        if (shouldFocus && document.activeElement !== container) {
          container.focus()
          // just focus the first element in the form
          shouldFocus = false
        }
      }
      // For inst-ui components error message is handled by messages prop
      if (!formError.instUIControlled) {
        const id = formError.containerId
        const element = (
          <FormattedErrorMessage
            message={formError.errorText}
            margin="0 0 xx-small 0"
            iconMargin="0 xx-small xxx-small 0"
          />
        )
        if (!errorRoots[id]) errorRoots[id] = render(element, errorsContainer)
        else rerender(errorRoots[id], element)
      }
    })
  }

  function validateSectionFormName() {
    const sectionNameValue = $edit_section_form.find('#course_section_name')[0].value
    const nameErrors = []
    if (!sectionNameValue?.trim()) {
      const error = {}
      error.containerId = '#course_section_name'
      error.errorsContainerId = '#course_section_name_errors'
      error.errorText = I18n.t('A section name is required')
      nameErrors.push(error)
    }
    if (sectionNameValue?.length > 255) {
      const error = {}
      error.containerId = '#course_section_name'
      error.errorsContainerId = '#course_section_name_errors'
      error.errorText = I18n.t('Section name is too long')
      nameErrors.push(error)
    }
    if (nameErrors.length > 0) {
      $('label[for="course_section_name"] > abbr').addClass('text-error')
    } else {
      $('label[for="course_section_name"] > abbr').removeClass('text-error')
    }
    return nameErrors
  }

  function validateSectionFormDates() {
    return [...validateSectionStart(), ...validateSectionEnd()]
  }

  function validateSectionStart() {
    const startDate = document.querySelector(`[name="${START_AT_DATE}"]`).value
    return validateDateTime(startDate, START_AT_DATE)
  }

  function validateSectionEnd() {
    let errors = []
    const endDate = document.querySelector(`[name="${END_AT_DATE}"]`).value

    errors = validateDateTime(endDate, END_AT_DATE)
    if (errors.length > 0) {
      return errors
    }

    const startDateTime = document.getElementById('start_datetime_value').value
    const endDateTime = document.getElementById('end_datetime_value').value
    errors = validateStartDateAfterEnd(startDateTime, endDateTime)
    return errors
  }

  // remove course_section_name errors if you begin to type.
  $edit_section_form.find('#course_section_name').on('input', function () {
    const container = $(this)
    if (container) {
      container.removeClass('error-outline')
    }
    errorRoots['#course_section_name']?.unmount()
    errorRoots['#course_section_name'] = null
    $('label[for="course_section_name"] > abbr').removeClass('text-error')
  })

  $edit_section_form.find('#course_section_name').on('blur', function (_e) {
    const validateFormErrors = validateSectionFormName()
    if (validateFormErrors.length > 0) {
      renderFormErrors(validateFormErrors)
    } else {
      const container = $(this)
      if (container) {
        container.removeClass('error-outline')
      }
      errorRoots['#course_section_name']?.unmount()
      errorRoots['#course_section_name'] = null
    }
  })

  $edit_section_form
    .formSubmit({
      beforeSubmit(data) {
        const validateFormErrors = [...validateSectionFormName(), ...validateSectionFormDates()]
        if (validateFormErrors.length > 0) {
          renderFormErrors(validateFormErrors, true)
          return false
        } else {
          data['course_section[start_at]'] = document.getElementById('start_datetime_value').value
          data['course_section[end_at]'] = document.getElementById('end_datetime_value').value

          $edit_section_form.hide()
          $edit_section_form.find('.name').text(data['course_section[name]']).show()
          $edit_section_form.loadingImage({image_size: 'small'})
        }
      },
      success(data) {
        const section = data.course_section
        $edit_section_form.loadingImage('remove')
        $('#section_name').text(section.name)
        $('span.sis_source_id').text(section.sis_source_id || '')
      },
      error(_data) {
        $edit_section_form.loadingImage('remove')
        $edit_section_form.show()
      },
    })
    .find(':text')
    .keycodes('return esc', function (event) {
      if (event.keyString === 'return') {
        $edit_section_form.submit()
      } else {
        $(this).parents('.section').find('.name').show()
        $edit_section_form.hide()
      }
    })
    .end()
    .find('.cancel_button')
    .on('click', () => {
      $edit_section_form.hide()
    })

  $edit_section_link.on('click', event => {
    event.preventDefault()
    $edit_section_form.toggle()
    $('#edit_section_form :text:visible:first').focus().select()
  })

  $('.user_list').on('click', '.unenroll_user_link', function (event) {
    event.preventDefault()
    $(this)
      .parents('.user')
      .confirmDelete({
        message: I18n.t(
          'confirms.delete_enrollment',
          'Are you sure you want to delete this enrollment permanently?',
        ),
        url: $(this).attr('href'),
        success() {
          $(this).slideUp(function () {
            $(this).remove()
          })
        },
      })
  })

  renderDatetimeField($('.datetime_field'))

  const uncrosslistLinkContainer = document.getElementById('uncrosslist_link_button_container')
  if (uncrosslistLinkContainer) {
    /** @type {{courseName: string, enrollmentsCount: number, courseId: string, sectionId: string, nonxlistCourseId: string}} */
    const props = JSON.parse(uncrosslistLinkContainer.dataset.props)
    render(
      <UncrosslistForm
        courseId={props.courseId}
        sectionId={props.sectionId}
        nonxlistCourseId={props.nonxlistCourseId}
        courseName={props.courseName}
        studentEnrollmentsCount={props.enrollmentsCount}
      />,
      uncrosslistLinkContainer,
    )
  }

  const crosslistLinkContainer = document.getElementById('crosslist_link_button_container')
  if (crosslistLinkContainer) {
    /** @type {{sectionId: string, isAlreadyCrosslisted: boolean, manageableCoursesUrl: string, confirmCrosslistUrl: string, crosslistUrl: string}} */
    const props = JSON.parse(crosslistLinkContainer.dataset.props)
    render(
      <CrosslistForm
        sectionId={props.sectionId}
        isAlreadyCrosslisted={props.isAlreadyCrosslisted}
        manageableCoursesUrl={props.manageableCoursesUrl}
        confirmCrosslistUrl={props.confirmCrosslistUrl}
        crosslistUrl={props.crosslistUrl}
      />,
      crosslistLinkContainer,
    )
  }
})
