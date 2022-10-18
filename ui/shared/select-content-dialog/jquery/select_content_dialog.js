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

import INST from 'browser-sniffer'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import FileSelectBox from '../react/components/FileSelectBox'
import UploadForm from '@canvas/files/react/components/UploadForm'
import CurrentUploads from '@canvas/files/react/components/CurrentUploads'
import splitAssetString from '@canvas/util/splitAssetString'
import FilesystemObject from '@canvas/files/backbone/models/FilesystemObject.coffee'
import BaseUploader from '@canvas/files/react/modules/BaseUploader'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'
import htmlEscape from 'html-escape'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import SelectContent from '../select_content'
import setDefaultToolValues from '../setDefaultToolValues'
import processSingleContentItem from '@canvas/deep-linking/processors/processSingleContentItem'
import {findLinkForService, getUserServices} from '@canvas/services/findLinkForService'
import '@canvas/datetime' /* datetime_field */
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/forms/jquery/jquery.instructure_forms' /* formSubmit, ajaxJSONFiles, getFormData, errorBox */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf */
import '@canvas/keycodes'
import '@canvas/loading-image'
import '@canvas/util/templateData'
import processMultipleContentItems from '@canvas/deep-linking/processors/processMultipleContentItems'

const I18n = useI18nScope('select_content_dialog')

const SelectContentDialog = {}

let fileSelectBox
let upload_form

SelectContentDialog.deepLinkingListener = event => {
  if (
    event.origin === ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN &&
    event.data &&
    event.data.subject === 'LtiDeepLinkingResponse'
  ) {
    if (event.data.content_items.length > 1) {
      return processMultipleContentItems(event)
        .then(result => {
          const $dialog = $('#resource_selection_dialog')
          $dialog.off('dialogbeforeclose', SelectContentDialog.dialogCancelHandler)
          $(window).off('beforeunload', SelectContentDialog.beforeUnloadHandler)

          if (result.every(item => item.type !== 'ltiResourceLink')) {
            $.flashError(I18n.t('Selected content contains non-LTI links.'))
            return
          }

          if (event.data.reloadpage) {
            window.location.reload()
          }
        })
        .catch(e => {
          $.flashError(I18n.t('Error retrieving content'))
          // eslint-disable-next-line no-console
          console.error(e)
        })
        .finally(() => {
          const $dialog = $('#resource_selection_dialog')
          $dialog.dialog('close')
        })
    } else if (event.data.content_items.length === 1) {
      return processSingleContentItem(event)
        .then(result => {
          const $dialog = $('#resource_selection_dialog')
          $dialog.off('dialogbeforeclose', SelectContentDialog.dialogCancelHandler)
          $(window).off('beforeunload', SelectContentDialog.beforeUnloadHandler)

          if (result.type !== 'ltiResourceLink') {
            $.flashError(I18n.t('Selected content is not an LTI link.'))
            return
          }

          const tool = $('#context_external_tools_select .tools .tool.selected').data('tool')
          SelectContentDialog.handleContentItemResult(result, tool)
        })
        .catch(e => {
          $.flashError(I18n.t('Error retrieving content'))
          // eslint-disable-next-line no-console
          console.error(e)
        })
        .finally(() => {
          const $dialog = $('#resource_selection_dialog')
          $dialog.dialog('close')
        })
    } else if (event.data.content_items.length === 0) {
      SelectContentDialog.closeAll()
    }
  }
}

SelectContentDialog.closeAll = function () {
  const $selectContextContentDialog = $('#select_context_content_dialog')
  const $resourceSelectionDialog = $('#resource_selection_dialog')

  $resourceSelectionDialog.off('dialogbeforeclose', SelectContentDialog.dialogCancelHandler)
  $(window).off('beforeunload', SelectContentDialog.beforeUnloadHandler)

  $resourceSelectionDialog.dialog('close')
  $selectContextContentDialog.dialog('close')
}

SelectContentDialog.attachDeepLinkingListner = function () {
  window.addEventListener('message', this.deepLinkingListener)
}

SelectContentDialog.detachDeepLinkingListener = function () {
  window.removeEventListener('message', this.deepLinkingListener)
}

SelectContentDialog.dialogCancelHandler = function (event) {
  const response = window.confirm(
    I18n.t('Are you sure you want to cancel? Changes you made may not be saved.')
  )
  if (!response) {
    event.preventDefault()
  }
}

SelectContentDialog.beforeUnloadHandler = function (e) {
  return (e.returnValue = I18n.t('Changes you made may not be saved.'))
}

SelectContentDialog.handleContentItemResult = function (result, tool) {
  if (ENV.DEFAULT_ASSIGNMENT_TOOL_NAME && ENV.DEFAULT_ASSIGNMENT_TOOL_URL) {
    setDefaultToolValues(result, tool)
  }

  $('#external_tool_create_url').val(result.url)
  $('#external_tool_create_title').val(result.title || tool.name)
  $('#external_tool_create_custom_params').val(JSON.stringify(result.custom))
  if (result.iframe) {
    $('#external_tool_create_iframe_width').val(result.iframe.width)
    $('#external_tool_create_iframe_height').val(result.iframe.height)
  }

  $('#context_external_tools_select .domain_message').hide()

  // content item with an assignment_id means that an assignment was already
  // created on the backend, so close this dialog without giving the user
  // any chance to make changes that would be discarded
  if (result.assignment_id) {
    $('#external_tool_create_assignment_id').val(result.assignment_id)
    $('#select_context_content_dialog .add_item_button').click()
    SelectContentDialog.closeAll()
  }
}

SelectContentDialog.Events = {
  init() {
    $('#context_external_tools_select .tools').on(
      'click',
      '.tool',
      this.onContextExternalToolSelect
    )
  },

  onContextExternalToolSelect(e, existingTool) {
    e.preventDefault()
    const $tool = existingTool || $(this)
    const toolName = $tool.find('a').text()

    SelectContentDialog.resetExternalToolFields()

    if ($tool.hasClass('selected') && !$tool.hasClass('resource_selection')) {
      $tool.removeClass('selected')

      $.screenReaderFlashMessage(I18n.t('Unselected external tool %{tool}', {tool: toolName}))
      return
    }

    $.screenReaderFlashMessage(I18n.t('Selected external tool %{tool}', {tool: toolName}))
    $tool.parents('.tools').find('.tool.selected').removeClass('selected')
    $tool.addClass('selected')

    if ($tool.hasClass('resource_selection')) {
      const tool = $tool.data('tool')
      const frameHeight = Math.max(Math.min($(window).height() - 100, 550), 100)
      const placement_type =
        (tool.placements.resource_selection && 'resource_selection') ||
        (tool.placements.assignment_selection && 'assignment_selection') ||
        (tool.placements.link_selection && 'link_selection')
      var placement = tool.placements[placement_type]
      const width = placement.selection_width
      const height = placement.selection_height
      let $dialog = $('#resource_selection_dialog')
      if ($dialog.length == 0) {
        $dialog = $('<div/>', {
          id: 'resource_selection_dialog',
          style: 'padding: 0; overflow-y: hidden;',
        })
        $dialog.append(`<div class="before_external_content_info_alert screenreader-only" tabindex="0">
            <div class="ic-flash-info">
              <div class="ic-flash__icon" aria-hidden="true">
                <i class="icon-info"></i>
              </div>
              ${htmlEscape(I18n.t('The following content is partner provided'))}
            </div>
          </div>`)
        $dialog.append(
          $('<iframe/>', {
            id: 'resource_selection_iframe',
            style: `width: 800px; height: ${frameHeight}px; max-height: 100%; border: 0;`,
            src: '/images/ajax-loader-medium-444.gif',
            borderstyle: '0',
            tabindex: '0',
            allow: iframeAllowances(),
            'data-lti-launch': 'true',
          })
        )
        if (window.ENV && window.ENV.FEATURES && window.ENV.FEATURES.lti_platform_storage) {
          $dialog.append(
            $('<iframe/>', {
              id: 'post_message_forwarding',
              name: 'post_message_forwarding',
              title: 'post_message_forwarding',
              src: '/post_message_forwarding',
              sandbox: 'allow-scripts allow-same-origin',
              style: 'display: none;',
            })
          )
        }
        $dialog.append(`<div class="after_external_content_info_alert screenreader-only" tabindex="0">
            <div class="ic-flash-info">
              <div class="ic-flash__icon" aria-hidden="true">
                <i class="icon-info"></i>
              </div>
              ${htmlEscape(I18n.t('The preceding content is partner provided'))}
            </div>
          </div>`)

        const $external_content_info_alerts = $dialog.find(
          '.before_external_content_info_alert, .after_external_content_info_alert'
        )

        const $iframe = $dialog.find('#resource_selection_iframe')

        $external_content_info_alerts.on('focus', function () {
          const iframeWidth = $iframe.outerWidth(true)
          const iframeHeight = $iframe.outerHeight(true)
          $iframe.css('border', '2px solid #0374B5')
          $(this).removeClass('screenreader-only')
          const alertHeight = $(this).outerHeight(true)
          $iframe
            .css('height', `${iframeHeight - alertHeight - 4}px`)
            .css('width', `${iframeWidth - 4}px`)
          $dialog.scrollLeft(0).scrollTop(0)
        })

        $external_content_info_alerts.on('blur', function () {
          const iframeWidth = $iframe.outerWidth(true)
          const iframeHeight = $iframe.outerHeight(true)
          const alertHeight = $(this).outerHeight(true)
          $dialog.find('#resource_selection_iframe').css('border', 'none')
          $(this).addClass('screenreader-only')
          $iframe.css('height', `${iframeHeight + alertHeight}px`).css('width', `${iframeWidth}px`)
          $dialog.scrollLeft(0).scrollTop(0)
        })

        $('body').append($dialog.hide())
        $dialog.on('dialogbeforeclose', SelectContentDialog.dialogCancelHandler)
        $dialog
          .dialog({
            autoOpen: false,
            width: 'auto',
            resizable: true,
            close() {
              SelectContentDialog.detachDeepLinkingListener()
              $(window).off('beforeunload', SelectContentDialog.beforeUnloadHandler)
              $dialog
                .find('#resource_selection_iframe')
                .attr('src', '/images/ajax-loader-medium-444.gif')
            },
            open: () => {
              SelectContentDialog.attachDeepLinkingListner()
            },
            title: I18n.t('link_from_external_tool', 'Link Resource from External Tool'),
          })
          .bind('dialogresize', function () {
            $(this)
              .find('#resource_selection_iframe')
              .add('.fix_for_resizing_over_iframe')
              .height($(this).height())
              .width($(this).width())
          })
          .bind('dialogresizestop', () => {
            $('.fix_for_resizing_over_iframe').remove()
          })
          .bind('dialogresizestart', function () {
            $(this)
              .find('#resource_selection_iframe')
              .each(function () {
                $('<div class="fix_for_resizing_over_iframe" style="background: #fff;"></div>')
                  .css({
                    width: this.offsetWidth + 'px',
                    height: this.offsetHeight + 'px',
                    position: 'absolute',
                    opacity: '0.001',
                    zIndex: 10000000,
                  })
                  .css($(this).offset())
                  .appendTo('body')
              })
          })
          .bind('selection', event => {
            const item = event.contentItems[0]
            if (item['@type'] === 'LtiLinkItem' && item.url) {
              SelectContentDialog.handleContentItemResult(item, tool)
            } else {
              alert(SelectContent.errorForUrlItem(item))

              SelectContentDialog.resetExternalToolFields()
            }
            $('#resource_selection_dialog #resource_selection_iframe').attr('src', 'about:blank')
            $dialog.off('dialogbeforeclose', SelectContentDialog.dialogCancelHandler)
            $('#resource_selection_dialog').dialog('close')

            if (item.placementAdvice.presentationDocumentTarget.toLowerCase() === 'window') {
              document.querySelector('#external_tool_create_new_tab').checked = true
            }
          })
      }
      $dialog
        .dialog('close')
        .dialog('option', 'width', width || 800)
        .dialog('option', 'height', height || frameHeight || 400)
        .dialog('open')
      $dialog.triggerHandler('dialogresize')
      let url = $.replaceTags(
        $('#select_content_resource_selection_url').attr('href'),
        'id',
        tool.definition_id
      )
      url = url + '?placement=' + placement_type + '&secure_params=' + $('#secure_params').val()
      if ($('#select_context_content_dialog').data('context_module_id')) {
        url += '&context_module_id=' + $('#select_context_content_dialog').data('context_module_id')
      }
      $dialog.find('#resource_selection_iframe').attr({src: url, title: tool.name})
      $(window).on('beforeunload', SelectContentDialog.beforeUnloadHandler)
    } else {
      const placements = $tool.data('tool').placements
      var placement = placements.assignment_selection || placements.link_selection
      $('#external_tool_create_url').val(placement.url || '')
      $('#context_external_tools_select .domain_message')
        .showIf($tool.data('tool').domain)
        .find('.domain')
        .text($tool.data('tool').domain)
      $('#external_tool_create_title').val(placement.title)
    }
  },
}

SelectContentDialog.extractContextExternalToolItemData = function () {
  const tool = $('#context_external_tools_select .tools .tool.selected').data('tool')
  let tool_type = 'context_external_tool'
  let tool_id = 0

  if (tool) {
    if (tool.definition_type == 'Lti::MessageHandler') {
      tool_type = 'lti/message_handler'
    }

    tool_id = tool.definition_id
  }

  return {
    'item[type]': tool_type,
    'item[id]': tool_id,
    'item[new_tab]': $('#external_tool_create_new_tab').attr('checked') ? '1' : '0',
    'item[indent]': $('#content_tag_indent').val(),
    'item[url]': $('#external_tool_create_url').val(),
    'item[title]': $('#external_tool_create_title').val(),
    'item[custom_params]': $('#external_tool_create_custom_params').val(),
    'item[assignment_id]': $('#external_tool_create_assignment_id').val(),
    'item[iframe][width]': $('#external_tool_create_iframe_width').val(),
    'item[iframe][height]': $('#external_tool_create_iframe_height').val(),
  }
}

SelectContentDialog.resetExternalToolFields = function () {
  $('#external_tool_create_url').val('')
  $('#external_tool_create_title').val('')
  $('#external_tool_create_custom_params').val('')
  $('#external_tool_create_assignment_id').val('')
  $('#external_tool_create_iframe_width').val('')
  $('#external_tool_create_iframe_height').val('')
}

$(document).ready(function () {
  const external_services = null
  const $dialog = $('#select_context_content_dialog')
  INST.selectContentDialog = function (options) {
    var options = options || {}
    const for_modules = options.for_modules
    const select_button_text = options.select_button_text || I18n.t('buttons.add_item', 'Add Item')
    const holder_name = options.holder_name || 'module'
    const dialog_title =
      options.dialog_title || I18n.t('titles.add_item_to_module', 'Add Item to Module')
    const allow_external_urls = for_modules
    $dialog.data('context_module_id', options.context_module_id)
    $dialog.data('submitted_function', options.submit)
    $dialog.find('.context_module_content').showIf(for_modules)
    $dialog.find('.holder_name').text(holder_name)
    $dialog.find('.add_item_button').text(select_button_text)
    $dialog.find('.select_item_name').showIf(!options.no_name_input)
    if (allow_external_urls && !external_services) {
      const $services = $('#content_tag_services').empty()
      getUserServices('BookmarkService', function (data) {
        for (const idx in data) {
          const service = data[idx].user_service
          const $service = $("<a href='#' class='bookmark_service no-hover'/>")
          $service.addClass(service.service)
          $service.data('service', service)
          $service.attr(
            'title',
            I18n.t('titles.find_links_using_service', 'Find links using %{service}', {
              service: service.service,
            })
          )
          const $img = $('<img/>')
          $img.attr('src', '/images/' + service.service + '_small_icon.png')
          $service.append($img)
          $service.click(function (event) {
            event.preventDefault()
            findLinkForService($(this).data('service').service, data => {
              $('#content_tag_create_url').val(data.url)
              $('#content_tag_create_title').val(data.title)
            })
          })
          $services.append($service)
          $services.append('&nbsp;&nbsp;')
        }
      })
    }
    $('#select_context_content_dialog #external_urls_select :text').val('')
    $('#select_context_content_dialog #context_module_sub_headers_select :text').val('')
    $('#add_module_item_select').change()
    $('#select_context_content_dialog .module_item_select').change()
    $('#select_context_content_dialog')
      .dialog({
        title: dialog_title,
        width: options.width || 400,
        height: options.height || 400,
        close() {
          if (options.close) {
            options.close()
          }
          upload_form?.onClose()
        },
      })
      .fixDialogButtons()

    const visibleModuleItemSelect = $(
      '#select_context_content_dialog .module_item_select:visible'
    )[0]
    if (visibleModuleItemSelect) {
      if (visibleModuleItemSelect.selectedIndex != -1) {
        $('.add_item_button').removeClass('disabled').attr('aria-disabled', false)
      } else {
        $('.add_item_button').addClass('disabled').attr('aria-disabled', true)
      }
    }
    $('#select_context_content_dialog').dialog('option', 'title', dialog_title)
  }
  $('#select_context_content_dialog .cancel_button').click(() => {
    $dialog.find('.alert').remove()
    $dialog.dialog('close')
  })
  $(
    '#select_context_content_dialog select, #select_context_content_dialog input[type=text], .module_item_select'
  ).keycodes('return', function (event) {
    if (!$('.add_item_button').hasClass('disabled')) {
      // button is enabled
      $(event.currentTarget).blur()
      $(this).parents('.ui-dialog').find('.add_item_button').last().click()
    }
  })
  $('#select_context_content_dialog .add_item_button').click(function () {
    const submit = function (item_data, close_dialog = true) {
      const submitted = $dialog.data('submitted_function')
      if (submitted && $.isFunction(submitted)) {
        submitted(item_data)
      }
      if (close_dialog) {
        setTimeout(() => {
          $dialog.dialog('close')
          $dialog.find('.alert').remove()
        }, 0)
      }
    }

    const item_type = $('#add_module_item_select').val()

    if (item_type == 'external_url') {
      var item_data = {
        'item[type]': $('#add_module_item_select').val(),
        'item[id]': $(
          '#select_context_content_dialog .module_item_option:visible:first .module_item_select'
        ).val(),
        'item[new_tab]': $('#external_url_create_new_tab').attr('checked') ? '1' : '0',
        'item[indent]': $('#content_tag_indent').val(),
      }

      item_data['item[url]'] = $('#content_tag_create_url').val()
      item_data['item[title]'] = $('#content_tag_create_title').val()

      if (item_data['item[url]'] === '') {
        $('#content_tag_create_url').errorBox(I18n.t('URL is required'))
      } else if (item_data['item[title]'] === '') {
        $('#content_tag_create_title').errorBox(I18n.t('Page Name is required'))
      } else {
        submit(item_data)
      }
    } else if (item_type == 'context_external_tool') {
      var item_data = SelectContentDialog.extractContextExternalToolItemData()
      if (item_data['item[assignment_id]']) {
        // don't keep fields populated after an assignment was created
        // since assignment creation via deep link requires another tool launch
        SelectContentDialog.resetExternalToolFields()
      }

      $dialog.find('.alert-error').remove()

      if (item_data['item[url]'] === '') {
        const $errorBox = $('<div />', {class: 'alert alert-error', role: 'alert'}).css({
          marginTop: 8,
        })
        $errorBox.text(
          I18n.t('errors.external_tool_url', "An external tool can't be saved without a URL.")
        )
        $dialog.prepend($errorBox)
      } else if (item_data['item[title]'] === '') {
        $('#external_tool_create_title').errorBox(I18n.t('Page Name is required'))
      } else {
        submit(item_data)
      }
    } else if (item_type == 'context_module_sub_header') {
      var item_data = {
        'item[type]': $('#add_module_item_select').val(),
        'item[id]': $(
          '#select_context_content_dialog .module_item_option:visible:first .module_item_select'
        ).val(),
        'item[indent]': $('#content_tag_indent').val(),
      }
      item_data['item[title]'] = $('#sub_header_title').val()
      submit(item_data)
    } else {
      const $options = $(
        '#select_context_content_dialog .module_item_option:visible:first .module_item_select option:selected'
      )
      $options.each(function () {
        const $option = $(this)
        let item_id = $option.val()
        let quiz_type
        if (item_type === 'quiz' && item_id !== 'new') {
          ;[quiz_type, item_id] = item_id.split('_')
        }
        if (item_type === 'quiz' && item_id === 'new') {
          quiz_type = $('input[name=quiz_engine_selection]:checked').val()
        }
        const quiz_lti = quiz_type === 'assignment'
        const item_data = {
          'item[type]': quiz_type || item_type,
          'item[id]': item_id,
          'item[title]': $option.text(),
          'item[indent]': $('#content_tag_indent').val(),
          quiz_lti,
        }
        if (item_data['item[id]'] == 'new') {
          const $urls = $(
            '#select_context_content_dialog .module_item_option:visible:first .new .add_item_url'
          )
          const url = quiz_lti ? $urls.last().attr('href') : $urls.attr('href')
          let data = $(
            '#select_context_content_dialog .module_item_option:visible:first'
          ).getFormData()
          if (quiz_lti) {
            data = {
              'assignment[title]': data['quiz[title]'],
              'assignment[assignment_group_id]': data['quiz[assignment_group_id]'],
              quiz_lti: 1,
            }
          }
          const process_upload = function (udata, done = true) {
            let obj

            // discussion_topics will come from real api v1 and so wont be nested behind a `discussion_topic` or 'wiki_page' root object
            if (
              item_data['item[type]'] === 'discussion_topic' ||
              item_data['item[type]'] === 'wiki_page' ||
              item_data['item[type]'] === 'attachment'
            ) {
              obj = udata
            } else {
              obj = udata[item_data['item[type]']] // e.g. data['wiki_page'] for wiki pages
            }

            $('#select_context_content_dialog').loadingImage('remove')
            if (item_data['item[type]'] === 'wiki_page') {
              item_data['item[id]'] = obj.page_id
            } else {
              item_data['item[id]'] = obj.id
            }
            if (item_data['item[type]'] === 'attachment') {
              // some browsers return a fake path in the file input value, so use the name returned by the server
              item_data['item[title]'] = obj.display_name
            } else {
              item_data['item[title]'] = $(
                '#select_context_content_dialog .module_item_option:visible:first .item_title'
              ).val()
              item_data['item[title]'] = item_data['item[title]'] || obj.display_name
            }
            const $option = $(document.createElement('option'))
            const obj_id = item_type === 'quiz' ? `${quiz_type || 'quiz'}_${obj.id}` : obj.id
            $option.val(obj_id).text(item_data['item[title]'])
            $('#' + item_type + 's_select')
              .find('.module_item_select option:last')
              .after($option)
            submit(item_data, done)
          }

          if (item_data['item[type]'] == 'assignment') {
            data['assignment[post_to_sis]'] = ENV.DEFAULT_POST_TO_SIS
          }

          if (item_data['item[type]'] == 'attachment') {
            BaseUploader.prototype.onUploadPosted = attachment => {
              let file_matches = false
              // if the uploaded file replaced and existing file that already has a module item, don't create a new item
              const adding_to_module_id = $dialog.data().context_module_id
              if (
                !Object.keys(ENV.MODULE_FILE_DETAILS).find(fdkey => {
                  file_matches =
                    ENV.MODULE_FILE_DETAILS[fdkey].content_id == attachment.replacingFileId &&
                    ENV.MODULE_FILE_DETAILS[fdkey].module_id == adding_to_module_id // eslint-disable-line eqeqeq
                  if (file_matches) ENV.MODULE_FILE_DETAILS[fdkey].content_id = attachment.id
                  return file_matches
                })
              ) {
                process_upload(attachment, false)
              }

              if (UploadQueue.length() === 0) {
                renderFileUploadForm()
                $dialog.find('.alert').remove()
                $dialog.dialog('close')
              }
            }
            BaseUploader.prototype.onUploadFailed = _err => {
              $('#select_context_content_dialog').loadingImage('remove')
              $('#select_context_content_dialog').errorBox(
                I18n.t('errors.failed_to_create_item', 'Failed to Create new Item')
              )
              renderFileUploadForm()
            }
            // Unmount progress component to reset state
            ReactDOM.unmountComponentAtNode($('#module_attachment_upload_progress')[0])
            UploadQueue.flush() // if there was an error uploading earlier, the queue has stuff in it we no longer want.
            upload_form.queueUploads()
            fileSelectBox.setDirty()
            renderCurrentUploads()
          } else {
            $.ajaxJSON(
              url,
              'POST',
              data,
              data => {
                process_upload(data)
              },
              data => {
                $('#select_context_content_dialog').loadingImage('remove')
                if (
                  data &&
                  data.errors &&
                  data.errors.title[0] &&
                  data.errors.title[0].message &&
                  data.errors.title[0].message === 'blank'
                ) {
                  $('#select_context_content_dialog').errorBox(
                    I18n.t('errors.assignment_name_blank', 'Assignment name cannot be blank.')
                  )
                  $('.item_title').focus()
                } else {
                  $('#select_context_content_dialog').errorBox(
                    I18n.t('errors.failed_to_create_item', 'Failed to Create new Item')
                  )
                }
              }
            )
          }
        } else {
          submit(item_data)
        }
      })
    }
  })
  SelectContentDialog.Events.init.bind(SelectContentDialog.Events)()
  const $tool_template = $('#context_external_tools_select .tools .tool:first').detach()
  $('#add_module_item_select').change(function () {
    // Don't disable the form button for these options
    const selectedOption = $(this).val()
    const doNotDisable = [
      'external_url',
      'context_external_tool',
      'context_module_sub_header',
    ].includes(selectedOption)
    if (doNotDisable) {
      $('.add_item_button').removeClass('disabled').attr('aria-disabled', false)
    } else {
      $('.add_item_button').addClass('disabled').attr('aria-disabled', true)
    }

    $('#select_context_content_dialog .module_item_option').hide()
    if ($(this).val() === 'attachment') {
      fileSelectBox = ReactDOM.render(
        React.createFactory(FileSelectBox)({
          contextString: ENV.context_asset_string,
        }),
        $('#module_item_select_file')[0]
      )
      fileSelectBox.refresh()
      $('#attachment_folder_id').on('change', update_foc)
      renderFileUploadForm()
      if (fileSelectBox.folderStore.getState().isLoading) {
        fileSelectBox.folderStore.addChangeListener(() => {
          renderFileUploadForm()
        })
      }
      if (fileSelectBox.fileStore.getState().isLoading) {
        fileSelectBox.fileStore.addChangeListener(() => {
          renderFileUploadForm()
        })
      }
    }
    $('#' + $(this).val() + 's_select')
      .show()
      .find('.module_item_select')
      .change()
    if ($(this).val() == 'context_external_tool') {
      const $select = $('#context_external_tools_select')
      if (!$select.hasClass('loaded')) {
        $select.find('.message').text('Loading...')
        const url = $('#select_context_content_dialog .external_tools_url').attr('href')
        $.ajaxJSON(
          url,
          'GET',
          {},
          data => {
            $select.find('.message').remove()
            $select.addClass('loaded')
            $select.find('.tools').empty()
            for (const idx in data) {
              const tool = data[idx]
              const $tool = $tool_template.clone(true)
              const placement =
                tool.placements.assignment_selection || tool.placements.link_selection
              $tool.toggleClass(
                'resource_selection',
                SelectContent.isContentMessage(placement, tool.placements)
              )
              $tool.fillTemplateData({
                data: tool,
                dataValues: [
                  'definition_type',
                  'definition_id',
                  'domain',
                  'name',
                  'placements',
                  'description',
                ],
              })
              $tool.data('tool', tool)
              $select.find('.tools').append($tool.show())
            }
          },
          _data => {
            $select.find('.message').text(I18n.t('errors.loading_failed', 'Loading Failed'))
          }
        )
      }
    }
  })
  $('#select_context_content_dialog').on('change', '.module_item_select', function () {
    const currentSelectItem = $(this)[0]

    if ($('#add_module_item_select').val() === 'attachment') {
      if (currentSelectItem) {
        // selectedIndex==0 for [new files]
        if (currentSelectItem.selectedIndex === 0) {
          update_foc()
        } else {
          enable_disable_submit_button(currentSelectItem.selectedIndex > 0)
        }
      }
    } else {
      enable_disable_submit_button(
        $(currentSelectItem).is(':hidden') || currentSelectItem.selectedIndex > -1
      )
    }

    if ($(this).val() == 'new') {
      $(this).parents('.module_item_option').find('.new').show().focus().select()
    } else {
      $(this).parents('.module_item_option').find('.new').hide()
    }
  })
})

$('#module_attachment_uploaded_data').on('change', function (event) {
  enable_disable_submit_button(event.target?.files?.length > 0)
})

function enable_disable_submit_button(enabled) {
  if (enabled) {
    $('.add_item_button').removeClass('disabled').attr('aria-disabled', false)
  } else {
    $('.add_item_button').addClass('disabled').attr('aria-disabled', true)
  }
}

function update_foc() {
  enable_disable_submit_button($('#module_attachment_uploaded_data')[0].files.length)
  renderFileUploadForm()
  // Unmount progress component to reset state
  ReactDOM.unmountComponentAtNode($('#module_attachment_upload_progress')[0])
}

function handleUploadOnChange(current_uploader_count) {
  if (current_uploader_count === 0) {
    upload_form.reset(true)
    renderFileUploadForm()
    enable_disable_submit_button(false)
  } else {
    // toggle from the choose files button to current uploads
    $('#module_attachment_upload_form').hide()
    $('#module_attachment_upload_progress').show()
  }
}

function getFileUploadFolder() {
  const selectedFolder = document.getElementById('attachment_folder_id')
  const folderId = selectedFolder.value
  const folder = {...fileSelectBox.getFolderById(folderId)}
  if (folder) {
    folder.files = (folder.files || []).map(f => new FilesystemObject(f))
  }
  return folder
}

const renameFileMessage = nameToUse => {
  return I18n.t(
    'A file named "%{name}" already exists in this folder. Do you want to replace the existing file?',
    {name: nameToUse}
  )
}

const lockFileMessage = nameToUse => {
  return I18n.t(
    'A locked file named "%{name}" already exists in this folder. Please enter a new name.',
    {name: nameToUse}
  )
}

function renderFileUploadForm() {
  const [contextType, contextId] = splitAssetString(ENV.context_asset_string, true)
  const folderProps = {
    currentFolder: getFileUploadFolder(),
    contextType,
    contextId,
    visible: true,
    allowSkip: true,
    inputId: 'module_attachment_uploaded_data',
    inputName: 'attachment[uploaded_data]',
    autoUpload: false,
    disabled: fileSelectBox.isLoading(),
    alwaysRename: false,
    alwaysUploadZips: true,
    onChange: update_foc,
    onRenameFileMessage: renameFileMessage,
    onLockFileMessage: lockFileMessage,
  }
  // only show the choose files + folder form if [new files] is selected
  if ($('#select_context_content_dialog').val() === 'new') {
    $('#module_attachment_upload_form').parents('.module_item_option').find('.new').show()

    enable_disable_submit_button($('#module_attachment_uploaded_data')[0].files.length)
  }
  // toggle from current uploads to the choose files button
  $('#module_attachment_upload_form').show()
  $('#module_attachment_upload_progress').hide()
  upload_form = ReactDOM.render(
    <UploadForm {...folderProps} />,
    $('#module_attachment_upload_form')[0]
  )
}

function renderCurrentUploads() {
  ReactDOM.render(
    <CurrentUploads onUploadChange={handleUploadOnChange} />,
    $('#module_attachment_upload_progress')[0]
  )
}

export default SelectContentDialog
