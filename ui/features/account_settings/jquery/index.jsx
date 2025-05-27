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
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
// eslint-disable-next-line import/no-named-as-default
import htmlEscape from '@instructure/html-escape'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import axios from '@canvas/axios'
import 'jqueryui/tabs'
import globalAnnouncements from './global_announcements'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' // formSubmit, getFormData, validateForm
import '@canvas/jquery/jquery.instructure_misc_helpers' // replaceTags
import '@canvas/jquery/jquery.instructure_misc_plugins' // confirmDelete, showIf, /\.log/
import '@canvas/loading-image'
import '@instructure/date-js' // Date.parse
import 'jquery-scroll-to-visible/jquery.scrollTo'
import {renderDatetimeField} from '@canvas/datetime/jquery/DatetimeField'
import doFetchApi from '@canvas/do-fetch-api-effect'
import ReactDOM from 'react-dom/client'
import ReportDescription from '../react/account_reports/ReportDescription'
import RunReportForm from '../react/account_reports/RunReportForm'
import RQDModal from '../react/components/RQDModal'
import OpenRegistrationWarning from '../react/components/OpenRegistrationWarning'
import ServiceDescriptionModal from '../react/components/ServiceDescriptionModal'
import {LoadTab} from '../../../shared/tabs/react/LoadTab'

const I18n = createI18nScope('account_settings')
const _settings_smallTablet = window.matchMedia('(min-width: 550px)').matches
const _settings_desktop = window.matchMedia('(min-width: 992px)').matches

// for report description modals
let descMount
let descRoot

export function openReportDescriptionLink(event) {
  event.preventDefault()

  const closeModal = () => {
    descRoot.render(null)
  }
  const title = $(this).parents('.title').find('span.title').text()
  const desc = $(this).parent('.reports').find('.report_description').html()

  if (descMount && descRoot) {
    descRoot.render(<ReportDescription title={title} descHTML={desc} closeModal={closeModal} />)
  }
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
  // for report configure modals
  let reportMount
  let reportRoot
  // for RQD popup (behind FF)
  const rqdMount = document.getElementById('rqd_mount')
  let rqdRoot
  if (rqdMount) {
    rqdRoot = ReactDOM.createRoot(rqdMount)
  }
  // for open registration warning (renders based on auth providers)
  const openRegMount = document.getElementById('open_registration_mount')
  let openRegRoot
  if (openRegMount) {
    openRegRoot = ReactDOM.createRoot(openRegMount)
  }
  // for service description modals (always in settings)
  const serviceMount = document.getElementById('service_mount')
  let serviceRoot
  if (serviceMount) {
    serviceRoot = ReactDOM.createRoot(serviceMount)
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

  $('#account_settings').on('submit', function (event) {
    const $this = $(this)

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

    // Check for quiz filter errors too
    const quizIPFilters = document.getElementById('account_settings_quiz_ip_filters')
    if (quizIPFilters) result = result && quizIPFilters.__performValidation()

    if (!result) event.preventDefault()
  })

  $('#account_settings_suppress_notifications').click(event => {
    if (event.target.checked) {
      const result = window.confirm(
        I18n.t(
          'suppress_notifications_warning',
          "You have 'Suppress notifications from being created and sent out' checked, are you sure you want to continue?",
        ),
      )
      if (!result) {
        $('#account_settings_suppress_notifications').prop('checked', false)
      }
    }
  })

  renderDatetimeField($('.datetime_field'), {
    addHiddenInput: true,
  })

  globalAnnouncements.bindDomEvents()

  function loadReportsTab(targetId) {
    if (targetId !== 'tab-reports-selected') return

    const splitContext = window.ENV.context_asset_string.split('_')
    const path = `/${splitContext[0]}s/${splitContext[1]}/reports_tab`

    fetch(path, {
      headers: {accept: 'text/html'},
    })
      .then(req => req.text())
      .then(html => {
        try {
          $('#tab-reports-mount').html(html)
          descMount = document.getElementById('report_desc_mount')
          descRoot = ReactDOM.createRoot(descMount)
          reportMount = document.getElementById('run_report_mount')
          reportRoot = ReactDOM.createRoot(reportMount)

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
            },
            error(_data) {
              $(this).loadingImage('remove')
            },
          })
          $('.configure_report_link').click(function (event) {
            event.preventDefault()

            const reportCell = $(this).closest('td')
            const reportRow = reportCell.closest('tr')
            const reportName = reportRow[0].id
            const path = reportCell.find('.report_dialog form').attr('action')
            const html = reportCell.find('.report_dialog').html()

            const closeModal = () => reportRoot.render(null)
            const onSuccess = reportName => {
              reportRoot.render(null)
              $(`#${reportName}`)
                .find('.run_report_link')
                .hide()
                .end()
                .find('.configure_report_link')
                .hide()
                .end()
                .find('.running_report_message')
                .show()

              const nextRow = $(`#${reportName}`).next('tr')
              nextRow.find('button.open_report_description_link').focus()
            }

            const setupJQuery = () => {
              const modalBody = document.getElementById('configure_modal_body')
              const provisioning_container = modalBody.querySelector('form#provisioning_csv_form')
              const sis_export_container = modalBody.querySelector('form#sis_export_csv_form')

              const setupCheckboxBehavior = container => {
                const checkboxes = container.querySelectorAll(
                  'input[type="checkbox"]:not(#parameters_created_by_sis):not(#parameters_include_deleted)',
                )

                container.onclick = () => {
                  const reportIsChecked = [...checkboxes].some(cb => cb.checked)
                  const createdBySis = container.querySelector('#parameters_created_by_sis')
                  const includeDeleted = container.querySelector('#parameters_include_deleted')

                  createdBySis.disabled = !reportIsChecked
                  includeDeleted.disabled = !reportIsChecked

                  if (!reportIsChecked) {
                    createdBySis.checked = false
                    includeDeleted.checked = false
                  }
                }
              }

              if (provisioning_container) setupCheckboxBehavior(provisioning_container)
              if (sis_export_container) setupCheckboxBehavior(sis_export_container)
            }
            reportRoot.render(
              <RunReportForm
                formHTML={html}
                onRender={setupJQuery}
                closeModal={closeModal}
                onSuccess={onSuccess}
                path={path}
                reportName={reportName}
              />,
            )
          })
        } catch {
          $('#tab-reports-mount').text(I18n.t('There are no reports for you to view.'))
        }
      })
      .catch(() => {
        $('#tab-reports-mount').text(I18n.t('There are no reports for you to view.'))
      })
  }

  function loadSecurityTab(targetId) {
    if (targetId !== 'tab-security-selected') return

    const splitContext = window.ENV.context_asset_string.split('_')
    const api = axios.create({})

    api
      .get(`/api/v1/${splitContext[0]}s/${splitContext[1]}/csp_settings`)
      .then(() => {
        import(
          /* webpackChunkName: "[request]" */
          '../react/index'
        )
          .then(({start}) => {
            start(document.getElementById('tab-security-mount'), {
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
            $('#tab-security-mount').text(I18n.t('Security Tab failed to load.'))
          })
      })
      .catch(() => {
        $('#tab-security-mount').text(I18n.t('Security Tab failed to load.'))
      })
  }

  LoadTab(loadReportsTab)
  LoadTab(loadSecurityTab)

  $('#account_settings_restrict_quantitative_data_value').click(event => {
    const lockbox = $('#account_settings_restrict_quantitative_data_locked')
    if (event.target.checked) {
      lockbox.prop('disabled', false)
    } else {
      lockbox.prop('checked', false)
      lockbox.prop('disabled', true)
    }
  })

  $('.rqd_help_btn').click(event => {
    event.preventDefault()

    const closeModal = () => {
      rqdRoot.render(null)
    }

    rqdRoot.render(<RQDModal closeModal={closeModal} />)
  })

  $('.open_registration_delegated_warning_btn').click(event => {
    event.preventDefault()

    const closeModal = () => {
      openRegRoot.render(null)
    }

    const loginUrl = $('.open_registration_delegated_warning_btn').data('url')
    openRegRoot.render(<OpenRegistrationWarning loginUrl={loginUrl} closeModal={closeModal} />)
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
    $.each(['id', 'name', 'for'], (_i, prop) => {
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
        'Are you sure you want to remove this account admin?',
      ),
      url: $(this).data('href'),
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
      '#account_settings_sis_default_grade_export_value',
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
      '#account_settings_sis_assignment_name_length_value',
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
      I18n.t('links.turnitin.confirm_settings', 'confirm Turnitin settings'),
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
              'invalid Turnitin settings, please check your account id and shared secret from Turnitin',
            ),
          )
        }
      },
      _data => {
        $link.text(
          I18n.t(
            'notices.turnitin.invalid_settings',
            'invalid Turnitin settings, please check your account id and shared secret from Turnitin',
          ),
        )
      },
    )
  })

  // Admins tab
  $('.add_users_link').click(addUsersLink)

  $('.service_help_dialog').each(function (_index) {
    const serviceName = $(this).attr('id').replace('_help_dialog', '')
    const serviceTitle = $(this).attr('title')
    const descHTML = $(this).html()

    $(`<button class="Button Button--icon-action" type="button">
        <i class="icon-question"></i>
        <span class="screenreader-only">${htmlEscape(I18n.t('About this service'))}</span>
      </button>`)
      .click(event => {
        event.preventDefault()

        const closeModal = () => {
          serviceRoot.render(null)
        }

        serviceRoot.render(
          <ServiceDescriptionModal
            descHTML={descHTML}
            serviceTitle={serviceTitle}
            closeModal={closeModal}
          />,
        )
      })
      .appendTo('label[for="account_services_' + serviceName + '"]')
  })

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

    async function onTermsTypeChange() {
      if ($terms_type.val() === 'custom') {
        $('#terms_of_service_modal').show()
        $rce_container.show()

        try {
          const {json, response} = await doFetchApi({
            path: '/api/v1/acceptable_use_policy',
          })

          if (response.ok) {
            RichContentEditor.loadNewEditor($textarea, {
              focus: true,
              manageParent: true,
              defaultContent: json?.content || '',
            })
          } else {
            console.error(
              `Failed to load Acceptable Use Policy content: Received ${response.status} ${response.statusText}`,
            )
          }
        } catch (error) {
          console.error('Failed to load Acceptable Use Policy content:', error)
        }
      } else {
        $rce_container.hide()
        $('#terms_of_service_modal').hide()
      }
    }
    onTermsTypeChange()
  }

  $('#account_settings_enable_inbox_signature_block').click(event => {
    const lockbox = $('#account_settings_disable_inbox_signature_block_for_students')
    if (event.target.checked) {
      lockbox.prop('disabled', false)
    } else {
      lockbox.prop('checked', false)
      lockbox.prop('disabled', true)
    }
  })

  $('#account_settings_enable_inbox_auto_response').click(event => {
    const lockbox = $('#account_settings_disable_inbox_auto_response_for_students')
    if (event.target.checked) {
      lockbox.prop('disabled', false)
    } else {
      lockbox.prop('checked', false)
      lockbox.prop('disabled', true)
    }
  })

  $('#account_settings_allow_assign_to_differentiation_tags_value').click(event => {
    const warningMsg = $('#differentiation_tags_account_settings_warning_message')
    const descriptionMsg = $('#differentiation_tags_account_settings_description_message')
    const diffTagsOriginallyEnabled = warningMsg.data('diffTagsOriginallyEnabled') === true
    if (!event.target.checked && diffTagsOriginallyEnabled) {
      warningMsg.show()
      descriptionMsg.hide()
    } else {
      warningMsg.hide()
      descriptionMsg.show()
    }
  })
})
