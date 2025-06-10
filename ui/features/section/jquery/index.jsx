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
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, formErrors */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/util/templateData'
import 'jqueryui/menu'
import 'jqueryui/autocomplete'
import PaginatedList from './PaginatedList'
import enrollmentTemplate from '../jst/enrollment.handlebars'
import sectionEnrollmentPresenter from '../sectionEnrollmentPresenter'
import '@canvas/context-cards/react/StudentContextCardTrigger'
import replaceTags from '@canvas/util/replaceTags'
import {renderDatetimeField} from '@canvas/datetime/jquery/DatetimeField'
import {createRoot} from 'react-dom/client'
import FormattedErrorMessage from '@canvas/assignments/react/FormattedErrorMessage'
import StartDateTimeInput from '../react/StartDateTimeInput'
import EndDateTimeInput from '../react/EndDateTimeInput'
import {validateDateTime, validateStartDateAfterEnd, START_AT_DATE, END_AT_DATE} from '../utils'

const I18n = createI18nScope('section')

$(document).ready(function () {
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

  const renderStartAt = () => {
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
      const root = createRoot(startDateTimeInput)
      root.render(
        <StartDateTimeInput
          initialValue={value}
          handleDateTimeChange={onChange}
        ></StartDateTimeInput>,
      )
    }
  }

  const renderEndAt = () => {
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
      const root = createRoot(endDateTimeInput)
      root.render(
        <EndDateTimeInput initialValue={value} handleDateTimeChange={onChange}></EndDateTimeInput>,
      )
    }
  }

  renderStartAt()
  renderEndAt()

  const errorRoots = {}

  const renderFormErrors = (formErrors, shouldFocus = false) => {
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
        const root = errorRoots[formError.containerId] ?? createRoot(errorsContainer)
        errorRoots[formError.containerId] = root
        root.render(
          <FormattedErrorMessage
            message={I18n.t('%{errorText}', {errorText: formError.errorText})}
            margin="0 0 xx-small 0"
            iconMargin="0 xx-small xxx-small 0"
          />,
        )
      }
    })
  }

  const validateSectionFormName = () => {
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

  const validateSectionFormDates = () => {
    return [...validateSectionStart(), ...validateSectionEnd()]
  }

  const validateSectionStart = () => {
    const startDate = document.querySelector(`[name="${START_AT_DATE}"]`).value
    return validateDateTime(startDate, START_AT_DATE)
  }

  const validateSectionEnd = () => {
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

  const validateCrossListForm = courseName => {
    const courseLookupValue = $('#course_autocomplete_id').val()
    const autocompleteValue = $('#course_autocomplete_id_lookup').val()
    const courseIdValue = $('#course_id').val()
    const error = {}
    clearCrossListFormErrors()
    if (courseIdValue && !courseLookupValue && !autocompleteValue) {
      error.containerId = '#course_id'
      error.errorsContainerId = '#course_id_errors'
      error.errorText = I18n.t(
        'errors.course_not_authorized_for_crosslist',
        '%{course_name} not authorized for cross-listing',
        {
          course_name:
            courseName ||
            I18n.t('default_course_name', 'Course ID "%{course_id}"', {
              course_id: $('#course_id').val(),
            }),
        },
      )
      renderFormErrors([error], true)
    } else if (courseName && !courseLookupValue) {
      error.containerId = '#course_autocomplete_id_lookup'
      error.errorsContainerId = '#course_autocomplete_id_lookup_errors'
      error.errorText = I18n.t(
        'errors.course_not_authorized_for_crosslist',
        '%{course_name} not authorized for cross-listing',
        {course_name: courseName},
      )
      renderFormErrors([error], true)
      $('#sis_id_holder,#account_name_holder').hide()
      $('#course_autocomplete_name').text('')
    } else if (!courseLookupValue && !courseName && !courseIdValue) {
      error.containerId = '#course_autocomplete_id_lookup'
      error.errorsContainerId = '#course_autocomplete_id_lookup_errors'
      error.errorText = I18n.t(
        'errors.missing_target_course_for_crosslist',
        'Not a valid course name',
      )
      renderFormErrors([error], true)
    } else if (courseLookupValue) {
      return true
    }

    return false
  }

  const clearCrossListFormErrors = () => {
    errorRoots['#course_autocomplete_id_lookup']?.unmount()
    errorRoots['#course_autocomplete_id_lookup'] = null
    errorRoots['#course_id']?.unmount()
    errorRoots['#course_id'] = null
    $('#course_autocomplete_id_lookup, #course_id').removeClass('error-outline')
  }

  // remove course_section_name errors if you begin to type.
  $edit_section_form.find('#course_section_name').on('input', function (e) {
    const container = $(this)
    if (container) {
      container.removeClass('error-outline')
    }
    errorRoots['#course_section_name']?.unmount()
    errorRoots['#course_section_name'] = null
    $('label[for="course_section_name"] > abbr').removeClass('text-error')
  })

  $edit_section_form.find('#course_section_name').blur(function (e) {
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
    .click(() => {
      $edit_section_form.hide()
    })

  $edit_section_link.click(event => {
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
  $('.uncrosslist_link').click(event => {
    event.preventDefault()
    $('#uncrosslist_form').dialog({
      width: 400,
      modal: true,
      zIndex: 1000,
    })
  })
  $('#uncrosslist_form .cancel_button')
    .click(_event => {
      $('#uncrosslist_form').dialog('close')
    })
    .submit(function () {
      $(this)
        .find('button')
        .prop('disabled', true)
        .filter('.submit_button')
        .text(I18n.t('status.removing_crosslisting_of_section', 'De-Cross-Listing Section...'))
    })
  $('.crosslist_link').click(event => {
    event.preventDefault()
    $('#crosslist_course_form').dialog({
      width: 450,
      modal: true,
      zIndex: 1000,
    })
    $('#course_autocomplete_id_lookup').val('')
    $('#course_id').val('').change()
    clearCrossListFormErrors()
  })
  $('#course_autocomplete_id_lookup')
    .autocomplete({
      source: $('#course_autocomplete_url').attr('href'),
      select(event, ui) {
        $('#course_id').val('').trigger('input')
        $('#crosslist_course_form').triggerHandler('id_entered', ui.item)
      },
    })
    .data('ui-autocomplete')._renderItem = function (ul, item) {
    return $('<li>')
      .data('ui-autocomplete-item', item)
      .append(
        $('<a>')
          .append($('<div>').text(item.label))
          .append(
            $('<div>')
              .addClass('secondary')
              .append(
                $('<small>').text(
                  item.sis_id
                    ? I18n.t(
                        'course.sisid_term',
                        'SIS ID: %{course_sisid} | Term: %{course_term}',
                        {
                          course_sisid: item.sis_id,
                          course_term: item.term,
                        },
                      )
                    : I18n.t('course.term', 'Term: %{course_term}', {
                        course_term: item.term,
                      }),
                ),
              ),
          ),
      )
      .appendTo(ul)
  }
  $('#course_id').keycodes('return', function (event) {
    event.preventDefault()
    $(this).change()
  })
  $('#course_autocomplete_id_lookup')
    .on('input', function (event) {
      const container = $(this)
      if (container) {
        container.removeClass('error-outline')
      }
      $('#course_autocomplete_id').val('')
      $('#course_id').val('')
      clearCrossListFormErrors()
    })
    .on('blur', function (event) {
      const CourseLookupValue = $('#course_autocomplete_id_lookup').val()
      if (CourseLookupValue) {
        validateCrossListForm()
      }
    })

  $('#course_id').on('input', function (event) {
    const container = $(this)
    if (container) {
      container.removeClass('error-outline')
    }
    clearCrossListFormErrors()
  })

  $('#course_id').bind('change', function () {
    $('#course_autocomplete_id_lookup').val('')
    $('#crosslist_course_form').triggerHandler('id_entered', {id: $(this).val()})
  })
  $('#crosslist_course_form .cancel_button').click(() => {
    $('#crosslist_course_form').dialog('close')
  })
  let latest_course_id = null
  $('#crosslist_course_form').bind('id_entered', (event, course) => {
    if (course.id == latest_course_id) {
      return
    }

    $('#course_autocomplete_id').val('')
    if (!course.id) {
      $('#sis_id_holder,#account_name_holder').hide()
      $('#course_autocomplete_name').text('')
      return
    }
    course.name =
      course.name ||
      I18n.t('default_course_name', 'Course ID "%{course_id}"', {course_id: course.id})
    $('#course_autocomplete_name_holder').show()
    const confirmingText = I18n.t('status.confirming_course', 'Confirming %{course_name}...', {
      course_name: course.name,
    })
    $('#course_autocomplete_name').text(confirmingText)
    $.screenReaderFlashMessage(confirmingText)
    $('#sis_id_holder,#account_name_holder').hide()
    $('#course_autocomplete_account_name').hide()
    const url = replaceTags($('#course_confirm_crosslist_url').attr('href'), 'id', course.id)
    latest_course_id = course.id
    const course_id_before_get = latest_course_id
    $.ajaxJSON(
      url,
      'GET',
      {},
      data => {
        if (course_id_before_get != latest_course_id) {
          return
        }
        if (data && data.allowed) {
          const template_data = {
            sis_id: data.course && data.course.sis_source_id,
            account_name: data.account && data.account.name,
          }
          $('#course_autocomplete_name_holder').fillTemplateData({data: template_data})
          $('#course_autocomplete_name').text(data.course.name)
          $.screenReaderFlashMessage(data.course.name)
          $('#sis_id_holder').showIf(template_data.sis_id)
          $('#account_name_holder').showIf(template_data.account_name)

          $('#course_autocomplete_id').val(data.course.id)
        } else {
          const errorText = I18n.t(
            'errors.course_not_authorized_for_crosslist',
            '%{course_name} not authorized for cross-listing',
            {course_name: course.name},
          )
          validateCrossListForm(course.name)
          $('#course_autocomplete_name').text('')
          $.screenReaderFlashError(errorText)
          $('#sis_id_holder,#account_name_holder').hide()
        }
      },
      _data => {
        $('#course_autocomplete_name').text(
          I18n.t('errors.confirmation_failed', 'Confirmation Failed'),
        )
      },
    )
  })
  $("#crosslist_course_form button[type='submit']").on('click', function (e) {
    e.preventDefault()
    if (validateCrossListForm()) {
      $('#crosslist_course_form').trigger('submit')
    }
  })
})
