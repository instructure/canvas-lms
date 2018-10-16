/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import _ from 'underscore'
import fcUtil from '../util/fcUtil'
import I18n from 'i18n!EditAppointmentGroupDetails'
import htmlEscape from 'str/htmlEscape'
import commonEventFactory from '../calendar/commonEventFactory'
import TimeBlockList from '../calendar/TimeBlockList'
import editAppointmentGroupTemplate from 'jst/calendar/editAppointmentGroup'
import genericSelectTemplate from 'jst/calendar/genericSelect'
import ContextSelector from '../calendar/ContextSelector'
import preventDefault from '../fn/preventDefault'
import 'jquery.ajaxJSON'
import 'jquery.disableWhileLoading'
import 'jquery.instructure_forms'

export default class EditAppointmentGroupDetails {
  constructor(selector, apptGroup, contexts, closeCB, event, useBetterScheduler) {
    this.apptGroup = apptGroup
    this.contexts = contexts
    this.closeCB = closeCB
    this.event = event
    this.useBetterScheduler = useBetterScheduler
    this.currentContextInfo = null
    this.appointment_group = {
      use_group_signup: this.apptGroup.participant_type === 'Group',
      ...this.apptGroup
    }

    $(selector).html(
      editAppointmentGroupTemplate({
        better_scheduler: this.useBetterScheduler,
        title: this.apptGroup.title,
        contexts: this.contexts,
        appointment_group: this.appointment_group,
        num_minutes: `<input
          type="number"
          pattern="[0-9]"
          name="duration"
          value="30"
          style="width: 40px"
          aria-label="${htmlEscape(I18n.t('Minutes per slot'))}"
        />`,
        num_participants: `<input
          type="number"
          pattern="[0-9]"
          name="participants_per_appointment"
          value="${htmlEscape(this.appointment_group.participants_per_appointment)}"
          min="1"
          style="width: 40px;"
          aria-label="${htmlEscape(I18n.t('Max users/groups per appointment'))}"
        />`,
        num_appointments: `<input
          type="number"
          pattern="[0-9]"
          name="max_appointments_per_participant"
          value="${htmlEscape(this.appointment_group.max_appointments_per_participant)}"
          min="1"
          style="width: 40px"
          aria-label="${htmlEscape(I18n.t('Maximum number of appointments a participant can attend'))}"
        />`
      })
    )

    this.contextsHash = {}
    this.contexts.forEach(c => (this.contextsHash[c.asset_string] = c))

    this.form = $(selector).find('form')
    const editableContexts = this.contexts.filter(c => !c.concluded)
    this.contextSelector = new ContextSelector(
      '.ag-menu-container',
      this.apptGroup,
      editableContexts,
      this.contextsChanged,
      this.toggleContextsMenu
    )

    if (this.editing()) {
      this.form.attr('action', this.apptGroup.url)

      // Don't let them change a bunch of fields once it's created
      this.form
        .find('.context_id')
        .val(this.apptGroup.context_code)
        .attr('disabled', true)
      this.form.find('select.context_id').change()

      this.disableGroups()
      if (this.apptGroup.participant_type === 'Group') {
        this.form.find('.group-signup-checkbox').prop('checked', true)
        this.form.find('.group_category').val(this.apptGroup.sub_context_codes[0])
      } else {
        this.form.find('.group-signup-checkbox').prop('checked', false)
      }

      $('.reservation_help').click(this.openHelpDialog)
    } else {
      // FIXME: put this url in ENV json or something
      this.form.attr('action', '/api/v1/appointment_groups')
    }

    this.form.find('.ag_contexts_selector').click(preventDefault(this.toggleContextsMenu))

    // make sure this is the spot
    const timeBlocks = (this.apptGroup.appointments || []).map(appt => [fcUtil.wrap(appt.start_at), fcUtil.wrap(appt.end_at), true])
    this.timeBlockList = new TimeBlockList(this.form.find(".time-block-list-body"), this.form.find(".splitter"), timeBlocks, { date: this.event && this.event.date })

    this.form.find('[name="slot_duration"]').change(e => {
      if (this.form.find('[name="autosplit_option"]').is(':checked')) {
        this.timeBlockList.split(e.target.value)
        return this.timeBlockList.render()
      }
    })

    this.form
      .find('[name="participant_visibility"]')
      .prop('checked', this.apptGroup.participant_visibility === 'protected')

    this.form.find('.group-signup-checkbox').change(jsEvent => {
      const checked = !!jsEvent.target.checked
      this.form.find('.per_appointment_groups_label').toggle(checked)
      this.form.find('.per_appointment_users_label').toggle(!checked)
      return this.form.find('.group-signup').toggle(checked)
    })
    this.form.find('.group-signup-checkbox').change()

    const $perSlotCheckbox = this.form.find('.appointment-blocks-per-slot-option-button')
    const $perSlotInput = this.form.find('[name="participants_per_appointment"]')
    const slotChangeHandler = e => this.perSlotChange($perSlotCheckbox, $perSlotInput)
    $.merge($perSlotCheckbox, $perSlotInput).on('change', slotChangeHandler)
    if (this.apptGroup.participants_per_appointment > 0) {
      $perSlotCheckbox.prop('checked', true)
      $perSlotInput.val(this.apptGroup.participants_per_appointment)
    } else {
      $perSlotInput.attr('disabled', true)
    }

    const $maxPerStudentCheckbox = this.form.find('.max-per-student-option')
    const $maxPerStudentInput = this.form.find('[name="max_appointments_per_participant"]')
    const maxApptHandler = e =>
      this.maxStudentAppointmentsChange($maxPerStudentCheckbox, $maxPerStudentInput)
    $.merge($maxPerStudentCheckbox, $maxPerStudentInput).on('change', maxApptHandler)
    const maxAppointmentsPerStudent = this.apptGroup.max_appointments_per_participant
    $maxPerStudentInput.val(maxAppointmentsPerStudent)
    if (maxAppointmentsPerStudent > 0 || this.creating()) {
      $maxPerStudentCheckbox.prop('checked', true)
      if (this.creating() && $maxPerStudentInput.val() === '') {
        $maxPerStudentInput.val('1')
      }
    } else {
      $maxPerStudentInput.attr('disabled', true)
    }

    if (this.apptGroup.workflow_state === 'active') {
      this.form
        .find('#appointment-blocks-active-button')
        .attr('disabled', true)
        .prop('checked', true)
    }

    this.form.submit(this.saveClick)
    if (this.useBetterScheduler) {
      this.form.find('.cancel_btn').click(this.cancel)
    } else {
      this.form.find('.save_without_publishing_link').click(this.saveWithoutPublishingClick)
    }
  }

  creating() {
    return !this.editing()
  }
  editing() {
    return this.apptGroup.id != null
  }

  perSlotChange(checkbox, input) {
    this.checkBoxInputChange(checkbox, input)
    const slotLimit = parseInt(input.val())
    return this.helpIconShowIf(
      checkbox,
      _.any(this.apptGroup.appointments, a => a.child_events_count > slotLimit)
    )
  }

  maxStudentAppointmentsChange(checkbox, input) {
    this.checkBoxInputChange(checkbox, input)
    const apptLimit = parseInt(input.val())
    const apptCounts = {}
    this.apptGroup.appointments && this.apptGroup.appointments.forEach(a => {
      a.child_events.forEach(e => {
        if (!apptCounts[e.user.id]) apptCounts[e.user.id] = 0
        apptCounts[e.user.id] += 1
      })
    })
    return this.helpIconShowIf(checkbox, _.any(apptCounts, (count, userId) => count > apptLimit))
  }

  // show/hide the help icon
  helpIconShowIf(checkbox, show) {
    const helpIcon = checkbox.closest('li').find('.reservation_help')
    if (show && checkbox.is(':checked')) {
      return helpIcon.removeClass('hidden')
    } else {
      return helpIcon.addClass('hidden')
    }
  }

  // enable/disable the input
  checkBoxInputChange(checkbox, input) {
    if (checkbox.prop('checked') && input.val() === '') {
      input.val('1')
    }
    return input.prop('disabled', !checkbox.prop('checked'))
  }

  openHelpDialog = e => {
    e.preventDefault()
    return $('#options_help_dialog').dialog({
      title: I18n.t('affect_reservations', 'How will this affect reservations?'),
      width: 400
    })
  }

  saveWithoutPublishingClick = jsEvent => {
    jsEvent.preventDefault()
    return this.save(false)
  }

  cancel = e => {
    e.preventDefault()
    return this.closeCB(false)
  }

  saveClick = jsEvent => {
    jsEvent.preventDefault()
    return this.save(true)
  }

  save = publish => {
    const data = this.form.getFormData({object_name: 'appointment_group'})

    const params = {
      'appointment_group[title]': data.title,
      'appointment_group[description]': data.description,
      'appointment_group[location_name]': data.location
    }

    if (data.max_appointments_per_participant_option === '1') {
      if (data.max_appointments_per_participant < 1) {
        $('[name="max_appointments_per_participant"]').errorBox(
          I18n.t('bad_max_appts', 'You must allow at least one appointment per participant')
        )
        return false
      } else {
        params['appointment_group[max_appointments_per_participant]'] =
          data.max_appointments_per_participant
      }
    } else {
      params['appointment_group[max_appointments_per_participant]'] = ''
    }

    params['appointment_group[new_appointments]'] = []
    if (!this.timeBlockList.validate()) {
      return false
    }
    this.timeBlockList.blocks().forEach(range => {
      params['appointment_group[new_appointments]'].push([
        $.unfudgeDateForProfileTimezone(range[0]).toISOString(),
        $.unfudgeDateForProfileTimezone(range[1]).toISOString()
      ])
    })

    if (data.per_slot_option === '1') {
      if (data.participants_per_appointment < 1) {
        $('[name="participants_per_appointment"]').errorBox(
          I18n.t('bad_per_slot', 'You must allow at least one appointment per time slot')
        )
        return false
      } else {
        params['appointment_group[participants_per_appointment]'] =
          data.participants_per_appointment
      }
    } else {
      params['appointment_group[participants_per_appointment]'] = ''
    }

    if (publish && this.apptGroup.workflow_state !== 'active') {
      params['appointment_group[publish]'] = '1'
    }

    params['appointment_group[participant_visibility]'] =
      data.participant_visibility === '1' ? 'protected' : 'private'

    // get the context/section info from @contextSelector instead
    delete data['context_codes[]']
    delete data['sections[]']

    const contextCodes = this.contextSelector.selectedContexts()
    if (contextCodes.length === 0) {
      $('.ag_contexts_selector').errorBox(
        I18n.t('context_required', 'You need to select a calendar')
      )
      return
    } else {
      params['appointment_group[context_codes]'] = contextCodes
    }

    if (data.use_group_signup === '1' && data.group_category_id) {
      params['appointment_group[sub_context_codes]'] = [data.group_category_id]
    } else {
      const sections = this.contextSelector.selectedSections()
      if (sections) {
        params['appointment_group[sub_context_codes]'] = sections
      }
    }

    if (this.creating()) {
      // TODO: Provide UI for specifying this
      params['appointment_group[min_appointments_per_participant]'] = 1
    }

    const onSuccess = data => {
      (data.new_appointments || []).forEach(eventData => {
        const event = commonEventFactory(eventData, this.contexts)
        $.publish('CommonEvent/eventSaved', event)
      })
      this.closeCB(true)
    }
    const onError = () => {}

    const method = this.editing() ? 'PUT' : 'POST'

    const deferred = $.ajaxJSON(this.form.attr('action'), method, params, onSuccess, onError)
    return this.form.disableWhileLoading(deferred)
  }

  activate = () => ({})

  contextsChanged = (contextCodes, sectionCodes) => {
    // dropdown text
    if (sectionCodes.length === 0 && contextCodes.length === 0) {
      this.form.find('.ag_contexts_selector').text(I18n.t('select_calendars', 'Select Calendars'))
    } else {
      let text
      if (contextCodes.length > 0) {
        const contextCode = contextCodes[0]
        text = this.contextsHash[contextCode].name
        if (contextCodes.length > 1) {
          text += ` ${I18n.t('and_n_contexts', 'and %{n} others', {
            n: I18n.n(contextCodes.length - 1)
          })}`
        }
        this.form.find('.ag_contexts_selector').text(text)
      }
      if (sectionCodes.length > 0) {
        const sectionCode = sectionCodes[0]
        const section = _.chain(this.contexts)
          .pluck('course_sections')
          .flatten()
          .find(s => s.asset_string === sectionCode)
          .value()
        text = section.name
        if (sectionCodes.length > 1) {
          text += ` ${I18n.t('and_n_sectionCodes', 'and %{n} others', {
            n: I18n.n(sectionCodes.length - 1)
          })}`
        }
        this.form.find('.ag_contexts_selector').text(text)
      }
    }

    // group selector
    const context = this.contextsHash[contextCodes[0]]
    if (
      contextCodes.length === 1 &&
      sectionCodes.length === 0 &&
      (context.group_categories && context.group_categories.length > 0)
    ) {
      this.enableGroups(context)
      if (this.apptGroup.sub_context_codes.length > 0) {
        this.form.find('[name=group_category_id]').prop('disabled', true)
      }
    } else {
      this.disableGroups()
    }
  }

  disableGroups() {
    this.form
      .find('.group-signup-checkbox')
      .attr('disabled', true)
      .prop('checked', false)
    this.form.find('.group-signup').hide()
  }

  enableGroups(contextInfo) {
    this.form.find('.group-signup-checkbox').attr('disabled', false)
    const groupsInfo = {
      cssClass: 'group_category',
      name: 'group_category_id',
      collection: contextInfo.group_categories
    }
    this.form.find('.group_select').html(genericSelectTemplate(groupsInfo))
  }

  toggleContextsMenu = jsEvent => {
    const $menu = $('.ag_contexts_menu').toggleClass('hidden')
    // For accessibility: put the user back where they started.
    if ($menu.hasClass('hidden')) $('.ag_contexts_selector').focus()
  }
}
