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

import INST from './INST'
import I18n from 'i18n!select_content_dialog'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import FileSelectBox from 'jsx/context_modules/FileSelectBox'
import _ from 'underscore'
import htmlEscape from 'str/htmlEscape'
import {uploadFile} from 'jsx/shared/upload_file'
import iframeAllowances from 'jsx/external_apps/lib/iframeAllowances'
import SelectContent from './lti/select_content'
import setDefaultToolValues from './lti/setDefaultToolValues'
import processSingleContentItem from 'jsx/deep_linking/processors/processSingleContentItem'
import {findLinkForService, getUserServices} from './findLinkForService'
import './jquery.instructure_date_and_time' /* datetime_field */
import './jquery.ajaxJSON'
import './jquery.instructure_forms' /* formSubmit, ajaxJSONFiles, getFormData, errorBox */
import 'jqueryui/dialog'
import 'compiled/jquery/fixDialogButtons'
import './jquery.instructure_misc_helpers' /* replaceTags */
import './jquery.instructure_misc_plugins' /* showIf */
import './jquery.keycodes'
import './jquery.loadingImg'
import './jquery.templateData'

const SelectContentDialog = {}

SelectContentDialog.deepLinkingListener = event => {
  if (
    event.origin === ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN &&
    event.data &&
    event.data.messageType === 'LtiDeepLinkingResponse'
  ) {
    processSingleContentItem(event)
      .then(result => {
        const $dialog = $('#resource_selection_dialog')
        const tool = $('#context_external_tools_select .tools .tool.selected').data('tool')

        $dialog.off('dialogbeforeclose', SelectContentDialog.dialogCancelHandler)
        $(window).off('beforeunload', SelectContentDialog.beforeUnloadHandler)

        if (result.type !== 'ltiResourceLink') {
          $.flashError(I18n.t('Selected content is not an LTI link.'))
          return
        }

        SelectContentDialog.handleContentItemResult(result, tool)
      })
      .catch(e => {
        $.flashError(I18n.t('Error retrieving content'))
        console.error(e)
      })
      .finally(() => {
        const $dialog = $('#resource_selection_dialog')
        $dialog.dialog('close')
      })
  }
}

SelectContentDialog.attachDeepLinkingListner = function() {
  window.addEventListener('message', this.deepLinkingListener)
}

SelectContentDialog.detachDeepLinkingListener = function() {
  window.removeEventListener('message', this.deepLinkingListener)
}

SelectContentDialog.dialogCancelHandler = function(event) {
  ;[]
  const response = confirm(
    I18n.t('Are you sure you want to cancel? Changes you made may not be saved.')
  )
  if (!response) {
    event.preventDefault()
  }
}

SelectContentDialog.beforeUnloadHandler = function(e) {
  return (e.returnValue = I18n.t('Changes you made may not be saved.'))
}

SelectContentDialog.handleContentItemResult = function(result, tool) {
  if (ENV.DEFAULT_ASSIGNMENT_TOOL_NAME && ENV.DEFAULT_ASSIGNMENT_TOOL_URL) {
    setDefaultToolValues(result, tool)
  }
  $('#external_tool_create_url').val(result.url)
  $('#external_tool_create_title').val(result.title || tool.name)
  $('#context_external_tools_select .domain_message').hide()
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
    if ($tool.hasClass('selected') && !$tool.hasClass('resource_selection')) {
      $tool.removeClass('selected')
      $('#external_tool_create_url').val('')
      $.screenReaderFlashMessage(I18n.t('Unselected external tool %{tool}', {tool: toolName}))
      return
    }
    $.screenReaderFlashMessage(I18n.t('Selected external tool %{tool}', {tool: toolName}))
    $tool
      .parents('.tools')
      .find('.tool.selected')
      .removeClass('selected')
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
          style: 'padding: 0; overflow-y: hidden;'
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
            style: 'width: 800px; height: ' + frameHeight + 'px; border: 0;',
            src: '/images/ajax-loader-medium-444.gif',
            borderstyle: '0',
            tabindex: '0',
            allow: iframeAllowances(),
            'data-lti-launch': 'true'
          })
        )
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

        const $iframe = $dialog.find('iframe')

        $external_content_info_alerts.on('focus', function(e) {
          const iframeWidth = $iframe.outerWidth(true)
          const iframeHeight = $iframe.outerHeight(true)
          $iframe.css('border', '2px solid #008EE2')
          $(this).removeClass('screenreader-only')
          const alertHeight = $(this).outerHeight(true)
          $iframe
            .css('height', `${iframeHeight - alertHeight - 4}px`)
            .css('width', `${iframeWidth - 4}px`)
          $dialog.scrollLeft(0).scrollTop(0)
        })

        $external_content_info_alerts.on('blur', function(e) {
          const iframeWidth = $iframe.outerWidth(true)
          const iframeHeight = $iframe.outerHeight(true)
          const alertHeight = $(this).outerHeight(true)
          $dialog.find('iframe').css('border', 'none')
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
              $dialog.find('iframe').attr('src', '/images/ajax-loader-medium-444.gif')
            },
            open: () => {
              SelectContentDialog.attachDeepLinkingListner()
            },
            title: I18n.t('link_from_external_tool', 'Link Resource from External Tool')
          })
          .bind('dialogresize', function() {
            $(this)
              .find('iframe')
              .add('.fix_for_resizing_over_iframe')
              .height($(this).height())
              .width($(this).width())
          })
          .bind('dialogresizestop', () => {
            $('.fix_for_resizing_over_iframe').remove()
          })
          .bind('dialogresizestart', function() {
            $(this)
              .find('iframe')
              .each(function() {
                $('<div class="fix_for_resizing_over_iframe" style="background: #fff;"></div>')
                  .css({
                    width: this.offsetWidth + 'px',
                    height: this.offsetHeight + 'px',
                    position: 'absolute',
                    opacity: '0.001',
                    zIndex: 10000000
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
              alert(
                I18n.t(
                  'invalid_lti_resource_selection',
                  'There was a problem retrieving a valid link from the external tool'
                )
              )
              $('#external_tool_create_url').val('')
              $('#external_tool_create_title').val('')
            }
            $('#resource_selection_dialog iframe').attr('src', 'about:blank')
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
      $dialog.find('iframe').attr('src', url)
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
  }
}

$(document).ready(function() {
  const external_services = null
  const $dialog = $('#select_context_content_dialog')
  INST.selectContentDialog = function(options) {
    var options = options || {}
    const for_modules = options.for_modules
    const select_button_text = options.select_button_text || I18n.t('buttons.add_item', 'Add Item')
    const holder_name = options.holder_name || 'module'
    const dialog_title =
      options.dialog_title || I18n.t('titles.add_item_to_module', 'Add Item to Module')
    const allow_external_urls = for_modules
    $dialog.data('submitted_function', options.submit)
    $dialog.find('.context_module_content').showIf(for_modules)
    $dialog.find('.holder_name').text(holder_name)
    $dialog.find('.add_item_button').text(select_button_text)
    $dialog.find('.select_item_name').showIf(!options.no_name_input)
    if (allow_external_urls && !external_services) {
      const $services = $('#content_tag_services').empty()
      getUserServices('BookmarkService', function(data) {
        for (const idx in data) {
          const service = data[idx].user_service
          const $service = $("<a href='#' class='bookmark_service no-hover'/>")
          $service.addClass(service.service)
          $service.data('service', service)
          $service.attr(
            'title',
            I18n.t('titles.find_links_using_service', 'Find links using %{service}', {
              service: service.service
            })
          )
          const $img = $('<img/>')
          $img.attr('src', '/images/' + service.service + '_small_icon.png')
          $service.append($img)
          $service.click(function(event) {
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
        }
      })
      .fixDialogButtons()

    const visibleModuleItemSelect = $(
      '#select_context_content_dialog .module_item_select:visible'
    )[0]
    if (visibleModuleItemSelect) {
      if (visibleModuleItemSelect.selectedIndex != -1) {
        $('.add_item_button')
          .removeClass('disabled')
          .attr('aria-disabled', false)
      } else {
        $('.add_item_button')
          .addClass('disabled')
          .attr('aria-disabled', true)
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
  ).keycodes('return', function(event) {
    if (!$('.add_item_button').hasClass('disabled')) {
      // button is enabled
      $(event.currentTarget).blur()
      $(this)
        .parents('.ui-dialog')
        .find('.add_item_button')
        .last()
        .click()
    }
  })
  $('#select_context_content_dialog .add_item_button').click(function() {
    const submit = function(item_data) {
      const submitted = $dialog.data('submitted_function')
      if (submitted && $.isFunction(submitted)) {
        submitted(item_data)
      }
      setTimeout(() => {
        $dialog.dialog('close')
        $dialog.find('.alert').remove()
      }, 0)
    }

    const item_type = $('#add_module_item_select').val()
    if (item_type == 'external_url') {
      var item_data = {
        'item[type]': $('#add_module_item_select').val(),
        'item[id]': $(
          '#select_context_content_dialog .module_item_option:visible:first .module_item_select'
        ).val(),
        'item[new_tab]': $('#external_url_create_new_tab').attr('checked') ? '1' : '0',
        'item[indent]': $('#content_tag_indent').val()
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
      const tool = $('#context_external_tools_select .tools .tool.selected').data('tool')
      let tool_type = 'context_external_tool'
      let tool_id = 0
      if (tool) {
        if (tool.definition_type == 'Lti::MessageHandler') {
          tool_type = 'lti/message_handler'
        }
        tool_id = tool.definition_id
      }
      var item_data = {
        'item[type]': tool_type,
        'item[id]': tool_id,
        'item[new_tab]': $('#external_tool_create_new_tab').attr('checked') ? '1' : '0',
        'item[indent]': $('#content_tag_indent').val()
      }
      item_data['item[url]'] = $('#external_tool_create_url').val()
      item_data['item[title]'] = $('#external_tool_create_title').val()
      $dialog.find('.alert-error').remove()
      if (item_data['item[url]'] === '') {
        const $errorBox = $('<div />', {class: 'alert alert-error', role: 'alert'}).css({
          marginTop: 8
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
        'item[indent]': $('#content_tag_indent').val()
      }
      item_data['item[title]'] = $('#sub_header_title').val()
      submit(item_data)
    } else {
      const $options = $(
        '#select_context_content_dialog .module_item_option:visible:first .module_item_select option:selected'
      )
      $options.each(function() {
        const $option = $(this)
        const item_data = {
          'item[type]': item_type,
          'item[id]': $option.val(),
          'item[title]': $option.text(),
          'item[indent]': $('#content_tag_indent').val()
        }
        if (item_data['item[id]'] == 'new') {
          $('#select_context_content_dialog').loadingImage()
          var url = $(
            '#select_context_content_dialog .module_item_option:visible:first .new .add_item_url'
          ).attr('href')
          let data = $(
            '#select_context_content_dialog .module_item_option:visible:first'
          ).getFormData()
          const callback = function(data) {
            let obj

            // discussion_topics will come from real api v1 and so wont be nested behind a `discussion_topic` or 'wiki_page' root object
            if (
              item_data['item[type]'] === 'discussion_topic' ||
              item_data['item[type]'] === 'wiki_page' ||
              item_data['item[type]'] === 'attachment'
            ) {
              obj = data
            } else {
              obj = data[item_data['item[type]']] // e.g. data['wiki_page'] for wiki pages
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
            $option.val(obj.id).text(item_data['item[title]'])
            $('#' + item_data['item[type]'] + 's_select')
              .find('.module_item_select option:last')
              .after($option)
            submit(item_data)
          }

          if (item_data['item[type]'] == 'assignment') {
            data['assignment[post_to_sis]'] = ENV.DEFAULT_POST_TO_SIS
          }
          if (item_data['item[type]'] == 'attachment') {
            const file = $('#module_attachment_uploaded_data')[0].files[0]
            var url = `/api/v1/folders/${data['attachment[folder_id]']}/files`
            data = {
              name: file.name,
              size: file.size,
              type: file.type,
              parent_folder_id: data['attachment[folder_id]'],
              on_duplicate: 'rename',
              no_redirect: true
            }
            uploadFile(url, data, file)
              .then(attachment => {
                callback(attachment)
              })
              .catch(response => {
                $('#select_context_content_dialog').loadingImage('remove')
                $('#select_context_content_dialog').errorBox(
                  I18n.t('errors.failed_to_create_item', 'Failed to Create new Item')
                )
              })
          } else {
            $.ajaxJSON(
              url,
              'POST',
              data,
              data => {
                callback(data)
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
  const initEvents = SelectContentDialog.Events.init.bind(SelectContentDialog.Events)()
  const $tool_template = $('#context_external_tools_select .tools .tool:first').detach()
  $('#add_module_item_select').change(function() {
    // Don't disable the form button for these options
    const selectedOption = $(this).val()
    const doNotDisable = [
      'external_url',
      'context_external_tool',
      'context_module_sub_header'
    ].includes(selectedOption)
    if (doNotDisable) {
      $('.add_item_button')
        .removeClass('disabled')
        .attr('aria-disabled', false)
    } else {
      $('.add_item_button')
        .addClass('disabled')
        .attr('aria-disabled', true)
    }

    $('#select_context_content_dialog .module_item_option').hide()
    if ($(this).val() === 'attachment') {
      ReactDOM.render(
        React.createFactory(FileSelectBox)({contextString: ENV.context_asset_string}),
        $('#module_item_select_file')[0]
      )
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
                  'description'
                ]
              })
              $tool.data('tool', tool)
              $select.find('.tools').append($tool.show())
            }
          },
          data => {
            $select.find('.message').text(I18n.t('errors.loading_failed', 'Loading Failed'))
          }
        )
      }
    }
  })
  $('#select_context_content_dialog').on('change', '.module_item_select', function() {
    const currentSelectItem = $(this)[0]
    if (currentSelectItem && currentSelectItem.selectedIndex > -1) {
      $('.add_item_button')
        .removeClass('disabled')
        .attr('aria-disabled', false)
    }

    if ($(this).val() == 'new') {
      $(this)
        .parents('.module_item_option')
        .find('.new')
        .show()
        .focus()
        .select()
    } else {
      $(this)
        .parents('.module_item_option')
        .find('.new')
        .hide()
    }
  })
})

export default SelectContentDialog
