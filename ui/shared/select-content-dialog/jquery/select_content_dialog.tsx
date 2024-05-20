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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import FileSelectBox from '../react/components/FileSelectBox'
import UploadForm from '@canvas/files/react/components/UploadForm'
import CurrentUploads from '@canvas/files/react/components/CurrentUploads'
import splitAssetString from '@canvas/util/splitAssetString'
import FilesystemObject from '@canvas/files/backbone/models/FilesystemObject'
import BaseUploader from '@canvas/files/react/modules/BaseUploader'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'
import htmlEscape from '@instructure/html-escape'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import SelectContent from '../select_content'
import setDefaultToolValues from '../setDefaultToolValues'
import {findLinkForService, getUserServices} from '@canvas/services/findLinkForService'
import '@canvas/datetime/jquery' /* datetime_field */
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, ajaxJSONFiles, getFormData, errorBox */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf */
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/util/templateData'
import type {DeepLinkResponse} from '@canvas/deep-linking/DeepLinkResponse'
import {contentItemProcessorPrechecks} from '@canvas/deep-linking/ContentItemProcessor'
import type {ResourceLinkContentItem} from '@canvas/deep-linking/models/ResourceLinkContentItem'
import type {EnvContextModules} from '@canvas/global/env/EnvContextModules'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import replaceTags from '@canvas/util/replaceTags'
import {EXTERNAL_CONTENT_READY, EXTERNAL_CONTENT_CANCEL} from '@canvas/external-tools/messages'

// @ts-expect-error
if (!('INST' in window)) window.INST = {}

// Allow unchecked access to ENV variables that should exist in this context
declare const ENV: GlobalEnv &
  EnvContextModules & {
    // From app/views/shared/_select_content_dialog.html.erb
    NEW_QUIZZES_BY_DEFAULT: boolean
  }

type LtiLaunchPlacement = {
  message_type:
    | 'LtiDeepLinkingRequest'
    | 'ContentItemSelectionRequest'
    | 'LtiResourceLinkRequest'
    | 'basic-lti-launch-request'
  url: string
  title: string
  selection_width: number
  selection_height: number
}

/**
 * A subset of all the placement types, the ones used
 */
type SelectContentPlacementType = 'resource_selection' | 'assignment_selection' | 'link_selection'

type LtiLaunchDefinition = {
  definition_type: 'ContextExternalTool' | 'Lti::MessageHandler'
  definition_id: string
  name: string
  url: string
  description: string
  domain: string
  // todo: the key here is actually a subset of string
  placements: Record<SelectContentPlacementType, LtiLaunchPlacement>
}

const I18n = useI18nScope('select_content_dialog')

const SelectContentDialog = {}

let fileSelectBox: FileSelectBox | undefined
let upload_form: UploadForm | undefined

export const externalContentReadyHandler = (event: MessageEvent, tool: LtiLaunchDefinition) => {
  const item = event.data.contentItems[0]
  if (item['@type'] === 'LtiLinkItem' && item.url) {
    handleContentItemResult(item, tool)
  } else {
    // eslint-disable-next-line no-alert
    window.alert(SelectContent.errorForUrlItem(item))

    resetExternalToolFields()
  }
  $('#resource_selection_dialog #resource_selection_iframe').attr('src', 'about:blank')
  const $dialog = $('#resource_selection_dialog')
  $dialog.off('dialogbeforeclose', dialogCancelHandler)
  $dialog.dialog('close')

  if (item.placementAdvice.presentationDocumentTarget.toLowerCase() === 'window') {
    setCreateNewTab(true)
  }
}

function setCreateNewTab(newTab: boolean) {
  const create_new_tab = document.querySelector('#external_tool_create_new_tab')
  if (create_new_tab && create_new_tab instanceof HTMLInputElement) {
    create_new_tab.checked = newTab
  }
}

const numberOrZero = (num: number | undefined) => (typeof num === 'undefined' ? 0 : num)

const isEqualOrIsArrayWithEqualValue = (
  value: string | number | string[] | undefined,
  toCompare: string
) => value === toCompare || (Array.isArray(value) && value[0] === toCompare)

export const deepLinkingResponseHandler = (event: MessageEvent<DeepLinkResponse>) => {
  if (event.data.content_items.length > 1) {
    try {
      contentItemProcessorPrechecks(event.data)
      const result = event.data.content_items

      const $dialog = $('#resource_selection_dialog')
      $dialog.off('dialogbeforeclose', dialogCancelHandler)
      $(window).off('beforeunload', beforeUnloadHandler)

      if (result.every(item => item.type !== 'ltiResourceLink')) {
        $.flashError(I18n.t('Selected content contains non-LTI links.'))
        return
      }

      if (event.data.reloadpage) {
        window.location.reload()
      }
    } catch (e) {
      $.flashError(I18n.t('Error retrieving content'))
      // eslint-disable-next-line no-console
      console.error(e)
    } finally {
      const $dialog = $('#resource_selection_dialog')
      $dialog.dialog('close')
    }
  } else if (event.data.content_items.length === 1) {
    try {
      contentItemProcessorPrechecks(event.data)
      const result = event.data.content_items[0]
      const $dialog = $('#resource_selection_dialog')
      $dialog.off('dialogbeforeclose', dialogCancelHandler)
      $(window).off('beforeunload', beforeUnloadHandler)

      if (result?.type !== 'ltiResourceLink') {
        $.flashError(I18n.t('Selected content is not an LTI link.'))
        return
      }
      const tool: LtiLaunchDefinition = $(
        '#context_external_tools_select .tools .tool.selected'
      ).data('tool')
      handleContentItemResult(result, tool)
    } catch (e) {
      $.flashError(I18n.t('Error retrieving content'))
      // eslint-disable-next-line no-console
      console.error(e)
    } finally {
      const $dialog = $('#resource_selection_dialog')
      $dialog.dialog('close')
    }
  } else if (event.data.content_items.length === 0) {
    closeAll()
  }
}

/**
 * Handles both LTI 1.1 (externalContentReady) and 1.3
 * (LtiDeepLinkingResponse) postMessages that contain
 * content items
 * @param {MessageEvent} event
 */
export const ltiPostMessageHandler = (tool: LtiLaunchDefinition) => (event: MessageEvent) => {
  if (event.origin === ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN && event.data) {
    if (event.data.subject === 'LtiDeepLinkingResponse') {
      deepLinkingResponseHandler(event)
    } else if (event.data.subject === EXTERNAL_CONTENT_READY) {
      externalContentReadyHandler(event, tool)
    } else if (event.data.subject === EXTERNAL_CONTENT_CANCEL) {
      $('#resource_selection_dialog').dialog('close')
    }
  }
}

export function closeAll() {
  const $selectContextContentDialog = $('#select_context_content_dialog')
  const $resourceSelectionDialog = $('#resource_selection_dialog')

  $resourceSelectionDialog.off('dialogbeforeclose', dialogCancelHandler)
  $(window).off('beforeunload', beforeUnloadHandler)

  $resourceSelectionDialog.dialog('close')
  $selectContextContentDialog.dialog('close')
}

export function dialogCancelHandler(
  // eslint-disable-next-line no-undef
  event: JQuery.TriggeredEvent<HTMLElement, any, any, any>
) {
  // eslint-disable-next-line no-alert
  const response = window.confirm(
    I18n.t('Are you sure you want to cancel? Changes you made may not be saved.')
  )
  if (!response) {
    event.preventDefault()
  }
}

export function beforeUnloadHandler(
  // eslint-disable-next-line no-undef
  e: JQuery.TriggeredEvent<Window & typeof globalThis, any, any, any>
) {
  return ((e as typeof e & {returnValue: string}).returnValue = I18n.t(
    'Changes you made may not be saved.'
  ))
}

const setValueIfDefined = (id: string, value: string | number | undefined): void => {
  if (typeof value !== 'undefined') {
    $(id).val(value)
  }
}
const setJsonValueIfDefined = (id: string, value: unknown): void => {
  if (typeof value !== 'undefined') {
    $(id).val(JSON.stringify(value))
  }
}

export function handleContentItemResult(
  result: ResourceLinkContentItem,
  tool: LtiLaunchDefinition
) {
  if (ENV.DEFAULT_ASSIGNMENT_TOOL_NAME && ENV.DEFAULT_ASSIGNMENT_TOOL_URL) {
    setDefaultToolValues(result, tool)
  }
  const populateUrl = (url: string) => {
    if (url && url !== '') {
      if (
        $('#external_tool_create_url').val() === '' ||
        window.ENV.FEATURES.lti_overwrite_user_url_input_select_content_dialog
      ) {
        $('#external_tool_create_url').val(url)
      }
    }
  }
  if (typeof result.url !== 'undefined' && result.url !== '') {
    populateUrl(result.url)
  } else if (tool.url !== '') {
    populateUrl(tool.url)
  }
  if (typeof result.title !== 'undefined') {
    $('#external_tool_create_title').val(result.title)
  } else if ($('#external_tool_create_title').is(':visible')) {
    // if external_tool_create_title is visible, then that means
    // we're on the module add page (or some other context where
    // the name is needed), so let's default to tool name here.
    $('#external_tool_create_title').val(tool.name)
  }
  $('#external_tool_create_custom_params').val(JSON.stringify(result.custom))
  setValueIfDefined('#external_tool_create_iframe_width', result.iframe?.width)
  setValueIfDefined('#external_tool_create_iframe_height', result.iframe?.height)
  setValueIfDefined('#external_tool_create_assignment_id', result.assignment_id)
  setJsonValueIfDefined('#external_tool_create_line_item', result.lineItem)
  setJsonValueIfDefined('#external_tool_create_submission', result.submission)
  setJsonValueIfDefined('#external_tool_create_available', result.available)
  if ('text' in result && typeof result.text === 'string') {
    $('#external_tool_create_description').val(result.text)
  }
  if (result.window && result.window.targetName === '_blank') {
    setCreateNewTab(true)
  }

  $('#context_external_tools_select .domain_message').hide()
}

export const Events = {
  init() {
    $('#context_external_tools_select .tools').on(
      'click',
      '.tool',
      this.onContextExternalToolSelect
    )
  },

  onContextExternalToolSelect(
    // eslint-disable-next-line no-undef
    e: JQuery.ClickEvent<HTMLElement, undefined, any, any>,
    // eslint-disable-next-line no-undef
    existingTool: JQuery<HTMLElement>
  ) {
    e.preventDefault()
    const $tool = existingTool || $(this)
    const toolName = $tool.find('a').text()

    resetExternalToolFields()

    if ($tool.hasClass('selected') && !$tool.hasClass('resource_selection')) {
      $tool.removeClass('selected')

      $.screenReaderFlashMessage(I18n.t('Unselected external tool %{tool}', {tool: toolName}))
      return
    }

    $.screenReaderFlashMessage(I18n.t('Selected external tool %{tool}', {tool: toolName}))
    $tool.parents('.tools').find('.tool.selected').removeClass('selected')
    $tool.addClass('selected')

    if ($tool.hasClass('resource_selection')) {
      const tool: LtiLaunchDefinition = $tool.data('tool')
      const frameHeight = Math.max(Math.min(numberOrZero($(window).height()) - 100, 550), 100)
      const placement_type: SelectContentPlacementType =
        (tool.placements.resource_selection && 'resource_selection') ||
        (tool.placements.assignment_selection && 'assignment_selection') ||
        (tool.placements.link_selection && 'link_selection')
      const placement = tool.placements[placement_type]
      const width = placement.selection_width
      const height = placement.selection_height
      let $dialog = $('#resource_selection_dialog')
      if ($dialog.length === 0) {
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

        const measurements = () => ({
          iframeWidth: numberOrZero($iframe.outerWidth(true)),
          iframeHeight: numberOrZero($iframe.outerHeight(true)),
        })

        $external_content_info_alerts.on('focus', function () {
          const {iframeWidth, iframeHeight} = measurements()
          $iframe.css('border', '2px solid #0374B5')
          $(this).removeClass('screenreader-only')
          const alertHeight = numberOrZero($(this).outerHeight(true))
          $iframe
            .css('height', `${iframeHeight - alertHeight - 4}px`)
            .css('width', `${iframeWidth - 4}px`)
          $dialog.scrollLeft(0).scrollTop(0)
        })

        $external_content_info_alerts.on('blur', function () {
          const {iframeWidth, iframeHeight} = measurements()
          const alertHeight = numberOrZero($(this).outerHeight(true))
          $dialog.find('#resource_selection_iframe').css('border', 'none')
          $(this).addClass('screenreader-only')
          $iframe.css('height', `${iframeHeight + alertHeight}px`).css('width', `${iframeWidth}px`)
          $dialog.scrollLeft(0).scrollTop(0)
        })

        $('body').append($dialog.hide())
        $dialog.on('dialogbeforeclose', dialogCancelHandler)
        const ltiPostMessageHandlerForTool = ltiPostMessageHandler(tool)
        $dialog
          .dialog({
            autoOpen: false,
            width: 'auto',
            resizable: true,
            close() {
              window.removeEventListener('message', ltiPostMessageHandlerForTool)
              $(window).off('beforeunload', beforeUnloadHandler)
              $dialog
                .find('#resource_selection_iframe')
                .attr('src', '/images/ajax-loader-medium-444.gif')
            },
            open: () => {
              window.addEventListener('message', ltiPostMessageHandlerForTool)
            },
            title: I18n.t('link_from_external_tool', 'Link Resource from External Tool'),
            modal: true,
            zIndex: 1000,
          })
          .bind('dialogresize', function () {
            $(this)
              .find('#resource_selection_iframe')
              .add('.fix_for_resizing_over_iframe')
              .height(numberOrZero($(this).height()))
              .width(numberOrZero($(this).width()))
          })
          .bind('dialogresizestop', () => {
            $('.fix_for_resizing_over_iframe').remove()
          })
          .bind('dialogresizestart', function () {
            const coordinatesNullable = $(this).offset()
            const coordinates: Record<string, number> =
              typeof coordinatesNullable === 'undefined'
                ? {}
                : (coordinatesNullable as unknown as Record<string, number>)
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
                  .css(coordinates)
                  .appendTo('body')
              })
          })
      }
      $dialog
        .dialog('close')
        .dialog('option', 'width', width || 800)
        .dialog('option', 'height', height || frameHeight || 400)
        .dialog('open')
      $dialog.triggerHandler('dialogresize')
      let url = replaceTags(
        $('#select_content_resource_selection_url').attr('href') as string,
        'id',
        tool.definition_id
      )
      url = url + '?placement=' + placement_type + '&secure_params=' + $('#secure_params').val()
      if ($('#select_context_content_dialog').data('context_module_id')) {
        url += '&context_module_id=' + $('#select_context_content_dialog').data('context_module_id')
        url += '&com_instructure_course_canvas_resource_type=context_module.external_tool'
      }
      $dialog.find('#resource_selection_iframe').attr({src: url, title: tool.name})
      $(window).on('beforeunload', beforeUnloadHandler)
    } else {
      const placements: Record<SelectContentPlacementType, LtiLaunchPlacement> =
        $tool.data('tool').placements
      const placement = placements.assignment_selection || placements.link_selection
      $('#external_tool_create_url').val(placement.url || '')
      $('#context_external_tools_select .domain_message')
        .showIf($tool.data('tool').domain)
        .find('.domain')
        .text($tool.data('tool').domain)
      if ($('#external_tool_create_title').is(':visible')) {
        $('#external_tool_create_title').val(placement.title)
      }
    }
  },
}

export function extractContextExternalToolItemData() {
  const tool: LtiLaunchDefinition = $('#context_external_tools_select .tools .tool.selected').data(
    'tool'
  )
  let tool_type = 'context_external_tool'
  let tool_id: string | number = 0

  if (tool) {
    if (tool.definition_type === 'Lti::MessageHandler') {
      tool_type = 'lti/message_handler'
    }

    tool_id = tool.definition_id
  }
  return {
    'item[type]': tool_type,
    'item[id]': tool_id,
    'item[new_tab]': $('#external_tool_create_new_tab').prop('checked') ? '1' : '0',
    'item[indent]': $('#content_tag_indent').val(),
    'item[url]': $('#external_tool_create_url').val(),
    'item[title]': $('#external_tool_create_title').val(),
    'item[custom_params]': $('#external_tool_create_custom_params').val(),
    'item[line_item]': $('#external_tool_create_line_item').val(),
    'item[assignment_id]': $('#external_tool_create_assignment_id').val(),
    'item[iframe][width]': $('#external_tool_create_iframe_width').val(),
    'item[iframe][height]': $('#external_tool_create_iframe_height').val(),
    'item[description]': $('#external_tool_create_description').val(),
    'item[submission]': $('#external_tool_create_submission').val(),
    'item[available]': $('#external_tool_create_available').val(),
  } as const
}

export function resetExternalToolFields() {
  $('#external_tool_create_url').val('')
  $('#external_tool_create_title').val('')
  $('#external_tool_create_custom_params').val('')
  $('#external_tool_create_line_item').val('')
  $('#external_tool_create_description').val('')
  $('#external_tool_create_submission').val('')
  $('#external_tool_create_available').val('')
  $('#external_tool_create_assignment_id').val('')
  $('#external_tool_create_iframe_width').val('')
  $('#external_tool_create_iframe_height').val('')
}

export type SelectContentDialogOptions = {
  for_modules?: boolean
  select_button_text?: string
  holder_name?: string
  dialog_title?: string
  context_module_id?: string
  height?: number
  width?: number
  submit?: Function
  no_name_input?: boolean
  close?: () => void
}

export const selectContentDialog = function (options?: SelectContentDialogOptions) {
  const $dialog = $('#select_context_content_dialog')
  options = options || {}
  const for_modules = options.for_modules
  const select_button_text = options.select_button_text || I18n.t('buttons.add_item', 'Add Item')
  const holder_name = options.holder_name || 'module'
  const dialog_title =
    options.dialog_title || I18n.t('titles.add_item_to_module', 'Add Item to Module')
  const allow_external_urls = for_modules
  $dialog.data('context_module_id', options.context_module_id || null)
  $dialog.data('submitted_function', options.submit || null)
  $dialog.find('.context_module_content').showIf(for_modules)
  $dialog.find('.holder_name').text(holder_name)
  $dialog.find('.add_item_button').text(select_button_text)
  $dialog.find('.select_item_name').showIf(!options.no_name_input)
  if (allow_external_urls) {
    const $services = $('#content_tag_services').empty()
    getUserServices('BookmarkService', function (data: any) {
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
          findLinkForService($(this).data('service').service, (data_: any) => {
            $('#content_tag_create_url').val(data_.url)
            $('#content_tag_create_title').val(data_.title)
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
        if (typeof options !== 'undefined' && options.close) {
          options.close()
        }
        upload_form?.onClose()
      },
      modal: true,
      zIndex: 1000,
    })
    .fixDialogButtons()

  const visibleModuleItemSelect = $('#select_context_content_dialog .module_item_select:visible')[0]
  if (visibleModuleItemSelect instanceof HTMLSelectElement) {
    if (visibleModuleItemSelect.selectedIndex !== -1) {
      $('.add_item_button').removeClass('disabled').attr('aria-disabled', 'false')
    } else {
      $('.add_item_button').addClass('disabled').attr('aria-disabled', 'true')
    }
  }
  $('#select_context_content_dialog').dialog('option', 'title', dialog_title)
}

$(document).ready(function () {
  const $dialog = $('#select_context_content_dialog')

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
    const submit = function (
      item_data: Record<string, string | number | string[] | undefined | boolean>,
      close_dialog = true
    ) {
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
    let item_data: Record<string, string | number | string[] | undefined | boolean>

    if (item_type === 'external_url') {
      item_data = {
        'item[type]': $('#add_module_item_select').val(),
        'item[id]': $(
          '#select_context_content_dialog .module_item_option:visible:first .module_item_select'
        ).val(),
        'item[new_tab]': $('#external_url_create_new_tab').prop('checked') ? '1' : '0',
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
    } else if (item_type === 'context_external_tool') {
      item_data = extractContextExternalToolItemData()

      $dialog.find('.alert-error').remove()

      // This would be nice to read from the options passed to select_content_dialog, but
      // that's not accessible from here. select_item_name won't be visible if the
      // no_name_input option is set.
      const no_name_input = $('#context_external_tools_select')
        .find('.select_item_name')
        .is(':hidden')

      if (item_data['item[url]'] === '') {
        const $errorBox = $('<div />', {class: 'alert alert-error', role: 'alert'}).css({
          marginTop: 8,
        })
        $errorBox.text(
          I18n.t('errors.external_tool_url', "An external tool can't be saved without a URL.")
        )
        $dialog.prepend($errorBox)
      } else if (item_data['item[title]'] === '' && !no_name_input) {
        $('#external_tool_create_title').errorBox(I18n.t('Page Name is required'))
      } else {
        submit(item_data)
      }
    } else if (item_type === 'context_module_sub_header') {
      item_data = {
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
        let quiz_type: string | number | string[] | undefined
        if (item_type === 'quiz' && typeof item_id === 'string' && item_id !== 'new') {
          ;[quiz_type, item_id] = item_id.split('_')
        }
        if (item_type === 'quiz' && item_id === 'new') {
          quiz_type = $('input[name=quiz_engine_selection]:checked').val()
          if (ENV.NEW_QUIZZES_BY_DEFAULT) {
            quiz_type = 'assignment'
          }
        }
        const quiz_lti = quiz_type === 'assignment'
        item_data = {
          'item[type]': quiz_type || item_type,
          'item[id]': item_id,
          'item[title]': $option.text(),
          'item[indent]': $('#content_tag_indent').val(),
          quiz_lti,
        }
        if (item_data['item[id]'] === 'new') {
          const $urls = $(
            '#select_context_content_dialog .module_item_option:visible:first .new .add_item_url'
          )
          const url = quiz_lti ? $urls.last().attr('href') : $urls.attr('href')
          let data = $(
            '#select_context_content_dialog .module_item_option:visible:first'
          ).getFormData<{
            'quiz[title]'?: string
            'quiz[assignment_group_id]'?: string
            'assignment[title]'?: string
            'assignment[assignment_group_id]'?: string
            'assignment[post_to_sis]'?: boolean
            quiz_lti?: number
          }>()
          if (quiz_lti) {
            data = {
              'assignment[title]': data['quiz[title]'],
              'assignment[assignment_group_id]': data['quiz[assignment_group_id]'],
              quiz_lti: 1,
            }
          }
          const process_upload = function (udata: any, done = true) {
            let obj

            // discussion_topics will come from real api v1 and so wont be nested behind a `discussion_topic` or 'wiki_page' root object
            if (
              item_data['item[type]'] === 'discussion_topic' ||
              item_data['item[type]'] === 'wiki_page' ||
              item_data['item[type]'] === 'attachment'
            ) {
              obj = udata
            } else {
              obj = udata[item_data['item[type]'] as string] // e.g. data['wiki_page'] for wiki pages
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
            const $option_ = $(document.createElement('option'))
            const obj_id = item_type === 'quiz' ? `${quiz_type || 'quiz'}_${obj.id}` : obj.id
            $option_.val(obj_id).text(item_data['item[title]'] as string)
            $('#' + item_type + 's_select')
              .find('.module_item_select option:last')
              .after($option_)
            submit(item_data, done)
          }

          if (item_data['item[type]'] === 'assignment') {
            data['assignment[post_to_sis]'] = ENV.DEFAULT_POST_TO_SIS
          }

          if (item_data['item[type]'] === 'attachment') {
            BaseUploader.prototype.onUploadPosted = (attachment: {
              replacingFileId: unknown
              id: string
            }) => {
              let file_matches = false
              // if the uploaded file replaced and existing file that already has a module item, don't create a new item
              const adding_to_module_id = $dialog.data().context_module_id
              if (
                !Object.keys(ENV.MODULE_FILE_DETAILS).find(fdkey => {
                  file_matches =
                    // eslint-disable-next-line eqeqeq
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
            ;(BaseUploader as any).prototype.onUploadFailed = (_err: any) => {
              $('#select_context_content_dialog').loadingImage('remove')
              $('#select_context_content_dialog').errorBox(
                I18n.t('errors.failed_to_create_item', 'Failed to Create new Item')
              )
              renderFileUploadForm()
            }
            // Unmount progress component to reset state
            ReactDOM.unmountComponentAtNode($('#module_attachment_upload_progress')[0])
            UploadQueue.flush() // if there was an error uploading earlier, the queue has stuff in it we no longer want.
            upload_form?.queueUploads()
            fileSelectBox?.setDirty()
            renderCurrentUploads()
          } else if (typeof url !== 'undefined') {
            $.ajaxJSON(
              url,
              'POST',
              data,
              (data_: unknown) => {
                process_upload(data_)
              },
              (data_: {errors?: {title?: {message?: string}[]}}) => {
                $('#select_context_content_dialog').loadingImage('remove')
                if (data_?.errors?.title?.[0]?.message === 'blank') {
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
  Events.init.bind(Events)()
  const $tool_template = $('#context_external_tools_select .tools .tool:first').detach()
  $('#add_module_item_select').change(function () {
    // Don't disable the form button for these options
    const selectedOption = $(this).val()
    const doNotDisable =
      typeof selectedOption === 'string' &&
      ['external_url', 'context_external_tool', 'context_module_sub_header'].includes(
        selectedOption
      )
    if (doNotDisable) {
      $('.add_item_button').removeClass('disabled').attr('aria-disabled', 'false')
    } else {
      $('.add_item_button').addClass('disabled').attr('aria-disabled', 'true')
    }

    $('#select_context_content_dialog .module_item_option').hide()
    if ($(this).val() === 'attachment') {
      // eslint-disable-next-line react/no-render-return-value
      fileSelectBox = ReactDOM.render(
        React.createFactory(FileSelectBox)({
          contextString: ENV.context_asset_string,
        }),
        $('#module_item_select_file')[0]
      )
      fileSelectBox.refresh()
      $('#attachment_folder_id').on('change', update_foc)
      renderFileUploadForm()
      if (fileSelectBox?.folderStore?.getState().isLoading) {
        fileSelectBox?.folderStore.addChangeListener(() => {
          renderFileUploadForm()
        })
      }
      if (fileSelectBox?.fileStore?.getState().isLoading) {
        fileSelectBox?.fileStore.addChangeListener(() => {
          renderFileUploadForm()
        })
      }
    }
    $('#' + $(this).val() + 's_select')
      .show()
      .find('.module_item_select')
      .change()
    if ($(this).val() === 'context_external_tool') {
      const $select = $('#context_external_tools_select')
      if (!$select.hasClass('loaded')) {
        $select.find('.message').text('Loading...')
        const url = $('#select_context_content_dialog .external_tools_url').attr('href')
        if (typeof url !== 'undefined') {
          $.ajaxJSON(
            url,
            'GET',
            {},
            (data: Array<LtiLaunchDefinition>) => {
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
            () => {
              $select.find('.message').text(I18n.t('errors.loading_failed', 'Loading Failed'))
            }
          )
        }
      }
    }
  })
  $('#select_context_content_dialog').on('change', '.module_item_select', function () {
    const currentSelectItem = $(this)[0]

    if (isEqualOrIsArrayWithEqualValue($('#add_module_item_select').val(), 'attachment')) {
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

    if (isEqualOrIsArrayWithEqualValue($(this).val(), 'new')) {
      $(this).parents('.module_item_option').find('.new').show().focus().select()
    } else {
      $(this).parents('.module_item_option').find('.new').hide()
    }
  })
})

$('#module_attachment_uploaded_data').on('change', function (event) {
  const target = event.target
  if (target instanceof HTMLInputElement) {
    enable_disable_submit_button(numberOrZero(target.files?.length) > 0)
  }
})

function enable_disable_submit_button(enabled: boolean) {
  if (enabled) {
    $('.add_item_button').removeClass('disabled').attr('aria-disabled', 'false')
  } else {
    $('.add_item_button').addClass('disabled').attr('aria-disabled', 'true')
  }
}

function update_foc() {
  const data_input = $('#module_attachment_uploaded_data')[0]
  if (data_input instanceof HTMLInputElement) {
    enable_disable_submit_button(numberOrZero(data_input.files?.length) > 0)
    renderFileUploadForm()
    // Unmount progress component to reset state
    ReactDOM.unmountComponentAtNode($('#module_attachment_upload_progress')[0])
  }
}

function handleUploadOnChange(current_uploader_count: number) {
  if (current_uploader_count === 0) {
    upload_form?.reset(true)
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
  if (selectedFolder !== null && selectedFolder instanceof HTMLSelectElement) {
    const folderId = selectedFolder.value
    const foundFolder: any = fileSelectBox?.getFolderById(folderId)
    const folder = foundFolder ? {...foundFolder} : {}
    if (folder) {
      folder.files = (folder.files || []).map((f: any) => new FilesystemObject(f))
    }
    return folder
  } else {
    return undefined
  }
}

const renameFileMessage = (nameToUse: string) => {
  return I18n.t(
    'A file named "%{name}" already exists in this folder. Do you want to replace the existing file?',
    {name: nameToUse}
  )
}

const lockFileMessage = (nameToUse: string) => {
  return I18n.t(
    'A locked file named "%{name}" already exists in this folder. Please enter a new name.',
    {name: nameToUse}
  )
}

function renderFileUploadForm() {
  const splitResult = splitAssetString(ENV.context_asset_string, true)
  if (typeof splitResult !== 'undefined') {
    const [contextType, contextId] = splitResult
    const folderProps = {
      currentFolder: getFileUploadFolder(),
      contextType,
      contextId,
      visible: true,
      allowSkip: true,
      inputId: 'module_attachment_uploaded_data',
      inputName: 'attachment[uploaded_data]',
      autoUpload: false,
      disabled: fileSelectBox?.isLoading(),
      alwaysRename: false,
      alwaysUploadZips: true,
      onChange: update_foc,
      onRenameFileMessage: renameFileMessage,
      onLockFileMessage: lockFileMessage,
    }
    // only show the choose files + folder form if [new files] is selected
    if (isEqualOrIsArrayWithEqualValue($('#select_context_content_dialog').val(), 'new')) {
      $('#module_attachment_upload_form').parents('.module_item_option').find('.new').show()
      const uploaded_data = $('#module_attachment_uploaded_data')[0]
      if (uploaded_data instanceof HTMLInputElement) {
        enable_disable_submit_button(numberOrZero(uploaded_data.files?.length) > 0)
      }
    }
    // toggle from current uploads to the choose files button
    $('#module_attachment_upload_form').show()
    $('#module_attachment_upload_progress').hide()
    upload_form = ReactDOM.render(
      <UploadForm {...folderProps} />,
      $('#module_attachment_upload_form')[0]
    ) as unknown as UploadForm
  }
}

function renderCurrentUploads() {
  ReactDOM.render(
    <CurrentUploads onUploadChange={handleUploadOnChange} />,
    $('#module_attachment_upload_progress')[0]
  )
}

export default SelectContentDialog
