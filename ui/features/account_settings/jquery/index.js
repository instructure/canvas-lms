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

import 'jqueryui/dialog'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import axios from '@canvas/axios'
import {setupCache} from 'axios-cache-adapter/src/index'
import 'jqueryui/tabs'
import globalAnnouncements from './global_announcements'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime/jquery' // date_field, time_field, datetime_field, /\$\.datetime/
import '@canvas/jquery/jquery.instructure_forms' // formSubmit, getFormData, validateForm
import '@canvas/jquery/jquery.instructure_misc_helpers' // replaceTags
import '@canvas/jquery/jquery.instructure_misc_plugins' // confirmDelete, showIf, /\.log/
import '@canvas/loading-image'
import 'date-js' // Date.parse
import 'jquery-scroll-to-visible/jquery.scrollTo'

const I18n = useI18nScope('account_settings')

let reportsTabHasLoaded = false

const _settings_smallTablet = window.matchMedia('(min-width: 550px)').matches
const _settings_desktop = window.matchMedia('(min-width: 992px)').matches

export function openReportDescriptionLink(event) {
  event.preventDefault()
  const title = $(this).parents('.title').find('span.title').text()
  const $desc = $(this).parent('.reports').find('.report_description')
  const responsiveWidth = _settings_desktop ? 800 : _settings_smallTablet ? 550 : 320
  $desc.clone().dialog({
    title,
    width: responsiveWidth,
    modal: true,
    zIndex: 1000,
  })
}

export function addUsersLink(event) {
  event.preventDefault()
  const $enroll_users_form = $('#enroll_users_form')
  $(this).hide()
  $enroll_users_form.show()
  $('html,body').scrollTo($enroll_users_form)
  $enroll_users_form.find('#admin_role_id').focus().select()
}

$(document).ready(function () {
  const settingsTabs = document
    .getElementById('account_settings_tabs')
    ?.querySelectorAll('ul>li>a[id^="tab"]')
  // find the index of tab whose id matches the URL's hash
  const initialTab = Array.from(settingsTabs || []).findIndex(
    t => `#${t.id}` === `${window.location.hash}-link`
  )

  if (settingsTabs && !window.location.hash) {
    // Sync the location hash with window.history, this fixes some issues with the browser back
    // button when going back to or from the settings tab
    const defaultTab = settingsTabs[0]?.href
    window.history.replaceState(null, null, defaultTab)
  }
  function checkFutureListingSetting() {
    if ($('#account_settings_restrict_student_future_view_value').is(':checked')) {
      $('.future_listing').show()
    } else {
      $('.future_listing').hide()
    }
  }
  checkFutureListingSetting()
  $('#account_settings_restrict_student_future_view_value').change(checkFutureListingSetting)

  $('#account_settings').submit(function () {
    const $this = $(this)
    let remove_ip_filters = true
    $('.ip_filter .value')
      .each(function () {
        $(this).removeAttr('name')
      })
      .filter(':not(.blank)')
      .each(function () {
        const name = $.trim(
          $(this).parents('.ip_filter').find('.name').val().replace(/\[|\]/g, '_')
        )
        if (name) {
          remove_ip_filters = false
          $(this).attr('name', 'account[ip_filters][' + name + ']')
        }
      })

    if (remove_ip_filters) {
      $this.append(
        "<input class='remove_ip_filters' type='hidden' name='account[remove_ip_filters]' value='1'/>"
      )
    } else {
      $this.find('.remove_ip_filters').remove() // just in case it's left over after a failed validation
    }

    const account_validations = {
      object_name: 'account',
      required: ['name'],
      property_validations: {
        name(value) {
          if (value && value.length > 255) {
            return I18n.t('account_name_too_long', 'Account Name is too long')
          }
        },
      },
    }

    let result = $this.validateForm(account_validations)

    // Work around for Safari to enforce help menu name validation until `required` is supported
    if ($('#custom_help_link_settings').length > 0) {
      const help_menu_validations = {
        object_name: 'account[settings]',
        required: ['help_link_name'],
        property_validations: {
          help_link_name(value) {
            if (value && value.length > 30) {
              return I18n.t('help_menu_name_too_long', 'Help menu name is too long')
            }
          },
        },
      }
      result = result && $this.validateForm(help_menu_validations)
    }

    if (!result) {
      return false
    }
  })

  $('#account_settings_suppress_notifications').click(event => {
    if (event.target.checked) {
      // eslint-disable-next-line no-alert
      const result = window.confirm(
        I18n.t(
          'suppress_notifications_warning',
          "You have 'Suppress notifications from being created and sent out' checked, are you sure you want to continue?"
        )
      )
      if (!result) {
        $('#account_settings_suppress_notifications').prop('checked', false)
      }
    }
  })

  $('.datetime_field').datetime_field({
    addHiddenInput: true,
  })

  globalAnnouncements.bindDomEvents()

  $('#account_settings_tabs').on('tabsactivate', (event, ui) => {
    try {
      const $tabLink = ui.newTab.children('a:first-child')
      const hash = new URL($tabLink.prop('href')).hash
      if (window.location.hash !== hash) {
        window.history.pushState(null, null, hash)
      }
      $tabLink.focus()
    } catch (_ignore) {
      // get here if `new URL` throws, but it shouldn't, and
      // there's really nothing we need to do about it
    }
  })

  $('#account_settings_tabs')
    .on('tabsbeforeactivate tabscreate', (event, ui) => {
      const tabId =
        event.type === 'tabscreate'
          ? window.location.hash.replace('#', '') + '-link'
          : $(ui.newTab.get(0)).children('a').get(0).id

      if (tabId === 'tab-reports-link' && !reportsTabHasLoaded) {
        reportsTabHasLoaded = true
        const splitContext = window.ENV.context_asset_string.split('_')

        fetch(`/${splitContext[0]}s/${splitContext[1]}/reports_tab`, {
          headers: {accept: 'text/html'},
        })
          .then(req => req.text())
          .then(html => {
            $('#tab-reports').html(html)
            $('#tab-reports .datetime_field').datetime_field()

            $('.open_report_description_link').click(openReportDescriptionLink)

            $('.run_report_link').click(function (clickEvent) {
              clickEvent.preventDefault()
              $(this).parent('form').submit()
            })

            $('.run_report_form').formSubmit({
              resetForm: true,
              beforeSubmit(_data) {
                $(this).loadingImage()
                return true
              },
              success(_data) {
                $(this).loadingImage('remove')
                const report = $(this).attr('id').replace('_form', '')
                $('#' + report)
                  .find('.run_report_link')
                  .hide()
                  .end()
                  .find('.configure_report_link')
                  .hide()
                  .end()
                  .find('.running_report_message')
                  .show()
                $(this).parent('.report_dialog').dialog('close')
              },
              error(_data) {
                $(this).loadingImage('remove')
                $(this).parent('.report_dialog').dialog('close')
              },
            })

            $('.configure_report_link').click(function (_event) {
              const provisioning_container = document.getElementById('provisioning_csv_form')
              const checkboxes = provisioning_container.querySelectorAll(
                'input[type="checkbox"]:not(#parameters_created_by_sis):not(#parameters_include_deleted)'
              )

              provisioning_container.onclick = function () {
                let reportIsChecked = false

                checkboxes.forEach(checkbox => {
                  if (checkbox.checked) {
                    reportIsChecked = true
                  }
                })

                if (reportIsChecked) {
                  provisioning_container.querySelector(
                    '#parameters_created_by_sis'
                  ).disabled = false
                  provisioning_container.querySelector(
                    '#parameters_include_deleted'
                  ).disabled = false
                } else {
                  provisioning_container.querySelector('#parameters_created_by_sis').checked = false
                  provisioning_container.querySelector('#parameters_created_by_sis').disabled = true
                  provisioning_container.querySelector(
                    '#parameters_include_deleted'
                  ).checked = false
                  provisioning_container.querySelector(
                    '#parameters_include_deleted'
                  ).disabled = true
                }
              }

              event.preventDefault()
              const data = $(this).data()
              let $dialog = data.$report_dialog
              const responsiveWidth = _settings_smallTablet ? 400 : 320
              if (!$dialog) {
                $dialog = data.$report_dialog = $(this)
                  .parent('td')
                  .find('.report_dialog')
                  .dialog({
                    autoOpen: false,
                    width: responsiveWidth,
                    title: I18n.t('titles.configure_report', 'Configure Report'),
                    modal: true,
                    zIndex: 1000,
                  })
              }
              $dialog.dialog('open')
            })
          })
          .catch(() => {
            $('#tab-reports').text(I18n.t('There are no reports for you to view.'))
          })
      } else if (tabId === 'tab-security-link') {
        // Set up axios and send a prefetch request to get the data we need,
        // this should make things appear to be much quicker once the bundle
        // loads in.
        const cache = setupCache({
          maxAge: 0.5 * 60 * 1000, // Hold onto the data for 30 seconds
          debug: true,
        })

        const api = axios.create({
          adapter: cache.adapter,
        })

        const splitContext = window.ENV.context_asset_string.split('_')

        api
          .get(`/api/v1/${splitContext[0]}s/${splitContext[1]}/csp_settings`)
          .then(() => {
            // Bring in the actual bundle of files to use
            import(
              /* webpackChunkName: "[request]" */
              '../react/index'
            )
              .then(({start}) => {
                start(document.getElementById('tab-security'), {
                  context: splitContext[0],
                  contextId: splitContext[1],
                  isSubAccount: !ENV.ACCOUNT.root_account,
                  initialCspSettings: ENV.CSP,
                  liveRegion: [
                    document.getElementById('flash_message_holder'),
                    document.getElementById('flash_screenreader_holder'),
                  ],
                  api,
                })
              })
              .catch(() => {
                // We really should never get here... but if we do... do something.
                $('#tab-security').text(I18n.t('Security Tab failed to load'))
              })
          })
          .catch(() => {
            // We really should never get here... but if we do... do something.
            $('#tab-security').text(I18n.t('Security Tab failed to load'))
          })
      }
    })
    .tabs({active: initialTab >= 0 ? initialTab : null})
    .show()

  $('#account_settings_restrict_quantitative_data_value').click(event => {
    const lockbox = $('#account_settings_restrict_quantitative_data_locked')
    if (event.target.checked) {
      lockbox.prop('disabled', false)
    } else {
      lockbox.prop('checked', false)
      lockbox.prop('disabled', true)
    }
  })
  $('.add_ip_filter_link').click(event => {
    event.preventDefault()
    const $filter = $('.ip_filter.blank:first').clone(true).removeClass('blank')
    $('#ip_filters').append($filter.show())
  })
  $('.delete_filter_link').click(function (event) {
    event.preventDefault()
    $(this).parents('.ip_filter').remove()
  })
  if ($('.ip_filter:not(.blank)').length === 0) {
    $('.add_ip_filter_link').click()
  }
  $('.ip_help_link').click(event => {
    event.preventDefault()
    $('#ip_filters_dialog').dialog({
      title: I18n.t('titles.what_are_quiz_ip_filters', 'What are Quiz IP Filters?'),
      width: 400,
      modal: true,
      zIndex: 1000,
    })
  })
  $('.rqd_help_btn').click(event => {
    event.preventDefault()
    $('#rqd_dialog').dialog({
      title: I18n.t('titles.rqd_help', 'Restrict Quantitative Data'),
      width: 400,
      modal: true,
      zIndex: 1000,
    })
  })

  $('.open_registration_delegated_warning_link').click(event => {
    event.preventDefault()
    $('#open_registration_delegated_warning_dialog').dialog({
      title: I18n.t(
        'titles.open_registration_delegated_warning_dialog',
        'An External Identity Provider is Enabled'
      ),
      width: 400,
      modal: true,
      zIndex: 1000,
    })
  })

  $('#account_settings_external_notification_warning_checkbox').on('change', function (_e) {
    $('#account_settings_external_notification_warning').val($(this).prop('checked') ? 1 : 0)
  })

  $('.custom_help_link .delete').click(function (event) {
    event.preventDefault()
    $(this).parents('.custom_help_link').find('.custom_help_link_state').val('deleted')
    $(this).parents('.custom_help_link').hide()
  })

  const $blankCustomHelpLink = $('.custom_help_link.blank').detach().removeClass('blank')
  let uniqueCounter = 1000
  $('.add_custom_help_link').click(event => {
    event.preventDefault()
    const $newContainer = $blankCustomHelpLink.clone(true).appendTo('#custom_help_links').show(),
      newId = uniqueCounter++
    // need to replace the unique id in the inputs so they get sent back to rails right,
    // chage the 'for' on the lables to match.
    $.each(['id', 'name', 'for'], (i, prop) => {
      $newContainer
        .find('[' + prop + ']')
        .attr(prop, (_i, previous) => previous.replace(/\d+/, newId))
    })
  })

  $('.remove_account_user_link').click(function (event) {
    event.preventDefault()
    const $item = $(this).parent('li')
    $item.confirmDelete({
      message: I18n.t(
        'confirms.remove_account_admin',
        'Are you sure you want to remove this account admin?'
      ),
      url: $(this).attr('href'),
      success() {
        $item.slideUp(function () {
          $(this).remove()
        })
      },
    })
  })

  $(
    '#enable_equella, ' +
      '#account_settings_sis_syncing_value, ' +
      '#account_settings_sis_default_grade_export_value'
  )
    .change(function () {
      const $myFieldset = $('#' + $(this).attr('id') + '_settings')
      const iAmChecked = $(this).prop('checked')
      $myFieldset.showIf(iAmChecked)
      if (!iAmChecked) {
        $myFieldset.find(':text').val('')
        $myFieldset.find(':checkbox').prop('checked', false)
      }
    })
    .change()

  $(
    '#account_settings_sis_syncing_value,' +
      '#account_settings_sis_default_grade_export_value,' +
      '#account_settings_sis_assignment_name_length_value'
  )
    .change(function () {
      const attr_id = $(this).attr('id')
      const $myFieldset = $('#' + attr_id + '_settings')
      const iAmChecked = $(this).prop('checked')
      $myFieldset.showIf(iAmChecked)
    })
    .change()

  $('.turnitin_account_settings').change(() => {
    $('.confirm_turnitin_settings_link').text(
      I18n.t('links.turnitin.confirm_settings', 'confirm Turnitin settings')
    )
  })

  $("input[name='account[services][avatars]']")
    .change(function () {
      if (this.checked) {
        $('#account_settings_gravatar_checkbox').show()
      } else {
        $('#account_settings_gravatar_checkbox').hide()
      }
    })
    .change()

  $('.confirm_turnitin_settings_link').click(function (event) {
    event.preventDefault()
    const $link = $(this)
    const url = $link.attr('href')
    const account = $('#account_settings').getFormData({object_name: 'account'})
    const turnitin_data = {
      turnitin_account_id: account.turnitin_account_id,
      turnitin_shared_secret: account.turnitin_shared_secret,
      turnitin_host: account.turnitin_host,
    }
    $link.text(I18n.t('notices.turnitin.checking_settings', 'checking Turnitin settings...'))
    $.getJSON(
      url,
      turnitin_data,
      data => {
        if (data && data.success) {
          $link.text(I18n.t('notices.turnitin.setings_confirmed', 'Turnitin settings confirmed!'))
        } else {
          $link.text(
            I18n.t(
              'notices.turnitin.invalid_settings',
              'invalid Turnitin settings, please check your account id and shared secret from Turnitin'
            )
          )
        }
      },
      _data => {
        $link.text(
          I18n.t(
            'notices.turnitin.invalid_settings',
            'invalid Turnitin settings, please check your account id and shared secret from Turnitin'
          )
        )
      }
    )
  })

  // Admins tab
  $('.add_users_link').click(addUsersLink)

  $('.service_help_dialog').each(function (_index) {
    const $dialog = $(this),
      serviceName = $dialog.attr('id').replace('_help_dialog', '')

    $dialog.dialog({
      autoOpen: false,
      width: 560,
      modal: true,
      zIndex: 1000,
    })

    $(`<button class="Button Button--icon-action" type="button">
        <i class="icon-question"></i>
        <span class="screenreader-only">${htmlEscape(I18n.t('About this service'))}</span>
      </button>`)
      .click(event => {
        event.preventDefault()
        $dialog.dialog('open')
      })
      .appendTo('label[for="account_services_' + serviceName + '"]')
  })

  function displayCustomEmailFromName() {
    let displayText = $('#account_settings_outgoing_email_default_name').val()
    if (displayText === '') {
      displayText = I18n.t('custom_text_blank', '[Custom Text]')
    }
    $('#custom_default_name_display').text(displayText)
  }
  $('.notification_from_name_option').on('change', () => {
    const $useCustom = $('#account_settings_outgoing_email_default_name_option_custom')
    const $customName = $('#account_settings_outgoing_email_default_name')
    if ($useCustom.prop('checked')) {
      $customName.removeAttr('disabled')
    } else {
      $customName.prop('disabled', true)
    }
  })
  $('#account_settings_outgoing_email_default_name').on('keyup', () => {
    displayCustomEmailFromName()
  })
  // Setup initial display state
  displayCustomEmailFromName()
  $('.notification_from_name_option').trigger('change')

  $('#account_settings_self_registration')
    .change(function () {
      $('#self_registration_type_radios').toggle(this.checked)
    })
    .trigger('change')

  $('#account_settings_global_includes')
    .change(function () {
      $('#global_includes_warning_message_wrapper').toggleClass('alert', this.checked)
    })
    .trigger('change')

  $('#account_settings_enable_as_k5_account_value')
    .change(function () {
      $('#k5_account_warning_message').toggleClass('shown', this.checked)
    })
    .trigger('change')

  const $rce_container = $('#custom_tos_rce_container')
  $('#terms_of_service_modal').hide()
  if ($rce_container.length > 0) {
    const $textarea = $rce_container.find('textarea')
    RichContentEditor.preloadRemoteModule()
    const $terms_type = $('#account_terms_of_service_terms_type').change(onTermsTypeChange)
    // eslint-disable-next-line no-inner-declarations
    async function onTermsTypeChange() {
      if ($terms_type.val() === 'custom') {
        $('#terms_of_service_modal').show()
        $rce_container.show()

        const url = '/api/v1/terms_of_service_custom_content'
        const defaultContent = await (await fetch(url)).text()

        RichContentEditor.loadNewEditor($textarea, {
          focus: true,
          manageParent: true,
          defaultContent,
        })
      } else {
        $rce_container.hide()
        $('#terms_of_service_modal').hide()
      }
    }
    onTermsTypeChange()
  }

  window.addEventListener('popstate', () => {
    const openTab = window.location.hash
    if (openTab) {
      document.querySelector(`[href="${openTab}"]`)?.click()
    }
  })
})
