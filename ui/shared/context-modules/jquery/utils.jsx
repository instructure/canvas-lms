/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {some} from 'lodash'
import React from 'react'
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import ModuleFile from '@canvas/files/backbone/models/ModuleFile'
import PublishCloud from '@canvas/files/react/components/PublishCloud'
import PublishableModuleItem from '../backbone/models/PublishableModuleItem'
import PublishIconView from '@canvas/publish-icon-view'
import {underscoreString} from '@canvas/convert-case'
import ContentTypeExternalToolTray from '@canvas/trays/react/ContentTypeExternalToolTray'
import {ltiState} from '@canvas/lti/jquery/messages'
import {addDeepLinkingListener} from '@canvas/deep-linking/DeepLinking'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'

const I18n = useI18nScope('context_modulespublic')

const content_type_map = {
  page: 'wiki_page',
  discussion: 'discussion_topic',
  external_tool: 'context_external_tool',
  sub_header: 'context_module_sub_header',
}

export function scrollTo($thing, time = 500) {
  if (!$thing || $thing.length === 0) return
  $('html, body').animate(
    {
      scrollTop: $thing.offset().top,
    },
    time
  )
}

export function refreshDuplicateLinkStatus($module) {
  if (
    !$module.find('.context_module_item.quiz').length &&
    !$module.find('.cannot-duplicate').length
  ) {
    $module.find('.duplicate_module_menu_item').removeAttr('hidden')
  } else {
    $module.find('.duplicate_module_menu_item').attr('hidden', true)
  }
}

export function addIcon($icon_container, css_class, message) {
  const $icon = $('<i data-tooltip></i>')
  $icon.attr('class', css_class).attr('title', message).attr('aria-label', message)
  $icon_container.empty().append($icon)
}

export function criterionMessage($mod_item) {
  if ($mod_item.hasClass('must_submit_requirement')) {
    return I18n.t('Must submit the assignment')
  } else if ($mod_item.hasClass('must_mark_done_requirement')) {
    return I18n.t('Must mark as done')
  } else if ($mod_item.hasClass('must_view_requirement')) {
    return I18n.t('Must view the page')
  } else if ($mod_item.hasClass('min_contribute_requirement')) {
    return I18n.t('Must contribute to the page')
  } else if ($mod_item.hasClass('min_score_requirement')) {
    return I18n.t('Must score at least a %{score}', {
      score: $mod_item.getTemplateData({textValues: ['min_score']}).min_score,
    })
  } else {
    return I18n.t('Not yet completed')
  }
}

export function prerequisitesMessage(list) {
  return I18n.t('Prerequisites: %{list}', {list})
}

export function onContainerOverlapped(event, sortableContainer, overlappingElement) {
  const sortableContainerStart = sortableContainer?.position().top
  const overlappingElementEnd = overlappingElement?.position().top + overlappingElement.height()
  const isOverlapped = sortableContainerStart < overlappingElementEnd
  // if the sortable container is overlapped by another element, the scroll should move when
  // the draggable item is getting closer to the overlapping element
  if (isOverlapped && event.pageY < overlappingElementEnd + 30) {
    const scrollTo_ = window.scrollY - event.clientY * 0.05
    $('html, body').scrollTop(scrollTo_)
  }
}

export function initPublishButton($el, data) {
  data = data || $el.data()
  if (data.moduleType === 'attachment') {
    // Module isNew if it was created with an ajax request vs being loaded when the page loads
    let moduleItem = {}

    if (data.isNew) {
      // Data will have content_details on the object
      moduleItem = data || {}

      // make sure styles are applied to new module items
      $el.attr('data-module-type', 'attachment')
    } else {
      // retrieve preloaded content details for the file item
      moduleItem = ENV.MODULE_FILE_DETAILS[parseInt(data.moduleItemId, 10)]
    }

    // Make sure content_details isn't empty. You don't want to break something.
    moduleItem.content_details = moduleItem.content_details || {}

    const file = new ModuleFile({
      type: 'file',
      id: moduleItem.content_id || moduleItem.id,
      locked: moduleItem.content_details.locked,
      hidden: moduleItem.content_details.hidden,
      unlock_at: moduleItem.content_details.unlock_at,
      lock_at: moduleItem.content_details.lock_at,
      display_name: moduleItem.content_details.display_name,
      thumbnail_url: moduleItem.content_details.thumbnail_url,
      usage_rights: moduleItem.content_details.usage_rights,
      module_item_id: parseInt(moduleItem.id, 10),
    })

    const props = {
      togglePublishClassOn: $el.parents('.ig-row')[0],
      userCanEditFilesForContext: ENV.MODULE_FILE_PERMISSIONS.manage_files_edit,
      usageRightsRequiredForContext: ENV.MODULE_FILE_PERMISSIONS.usage_rights_required,
      fileName: file.displayName(),
    }

    const fileFauxView = {
      render: () => {
        const model = $el.data('view').model
        ReactDOM.render(
          <PublishCloud {...props} model={model} disabled={model.get('disabled')} />,
          $el[0]
        )
        // to look disable, we need to add the class here
        $el[0].classList[model.get('disabled') ? 'add' : 'remove']('disabled')
      },
      model: file,
    }
    file.view = fileFauxView
    $el.data('view', fileFauxView)

    fileFauxView.render()

    return fileFauxView // Pretending this is a backbone view
  }

  const model = new PublishableModuleItem({
    module_type: data.moduleType,
    content_id: data.contentId,
    id: data.id,
    module_id: data.moduleId,
    module_item_id: data.moduleItemId,
    module_item_name: data.moduleItemName,
    course_id: data.courseId,
    published: data.published,
    publishable: data.publishable,
    unpublishable: data.unpublishable,
    publish_at: data.publishAt,
    quiz_lti: data.quizLti,
  })

  const viewOptions = {
    model,
    title: data.publishTitle,
    el: $el[0],
  }

  const view = new PublishIconView(viewOptions)
  const row = $el.closest('.ig-row')

  if (data.published) {
    row.addClass('ig-published')
  }
  // TODO: need to go find this item in other modules and update their state
  view.render()
  return view
}

export function setExpandAllButtonVisible(visible) {
  const element = ENV.FEATURES.instui_header ? 
    $('#expand_collapse_all').parent() : 
    $('#expand_collapse_all')
  visible ? element.show() : element.hide()
}

export function setExpandAllButton() {
  let someVisible = false
  $('#context_modules .context_module .content').each(function () {
    if ($(this).css('display') === 'block') {
      someVisible = true
    }
  })

  if (ENV.FEATURES.instui_header) {
    $('#expand_collapse_all').children().children().text(someVisible ? I18n.t('Collapse All') : I18n.t('Expand All'))
  }
  else {
    $('#expand_collapse_all').text(someVisible ? I18n.t('Collapse All') : I18n.t('Expand All'))
  }
  
  $('#expand_collapse_all').attr(
    'aria-label',
    someVisible ? I18n.t('Collapse All Modules') : I18n.t('Expand All Modules')
  )
  $('#expand_collapse_all').data('expand', !someVisible)
  $('#expand_collapse_all').attr('aria-expanded', someVisible ? 'true' : 'false')
}

export function setExpandAllButtonHandler() {
  $('#expand_collapse_all').click(function () {
    const shouldExpand = $(this).data('expand')

    if (ENV.FEATURES.instui_header) {
      $(this).children().children().text(shouldExpand ? I18n.t('Collapse All') : I18n.t('Expand All'))
    }
    else {
      $(this).text(shouldExpand ? I18n.t('Collapse All') : I18n.t('Expand All'))
    }

    $(this).attr(
      'aria-label',
      shouldExpand ? I18n.t('Collapse All Modules') : I18n.t('Expand All Modules')
    )
    $(this).data('expand', !shouldExpand)
    $(this).attr('aria-expanded', shouldExpand ? 'true' : 'false')

    $('.context_module').each(function () {
      const $module = $(this)
      if (
        (shouldExpand && $module.find('.content:visible').length === 0) ||
        (!shouldExpand && $module.find('.content:visible').length > 0)
      ) {
        const callback = function () {
          $module
            .find('.collapse_module_link')
            .css('display', shouldExpand ? 'inline-block' : 'none')
          $module.find('.expand_module_link').css('display', shouldExpand ? 'none' : 'inline-block')
          $module.find('.footer .manage_module').css('display', '')
          $module.toggleClass('collapsed_module', shouldExpand)
        }
        $module.find('.content').slideToggle({
          queue: false,
          done: callback(),
        })
      }
    })

    const url = $(this).data('url')
    const collapse = shouldExpand ? '0' : '1'
    $.ajaxJSON(url, 'POST', {collapse})
  })
}

export function resetExpandAllButtonBindings() {
  $('#expand_collapse_all').off('click');
}

export function updateProgressionState($module) {
  const id = $module.attr('id').substring(15)
  const $progression = $('#current_user_progression_list .progression_' + id)
  const data = $progression.getTemplateData({
    textValues: ['context_module_id', 'workflow_state', 'collapsed', 'current_position'],
  })
  $module = $('#context_module_' + data.context_module_id)
  let progression_state = data.workflow_state
  const progression_state_capitalized =
    progression_state && progression_state.charAt(0).toUpperCase() + progression_state.substring(1)

  $module.addClass(progression_state)

  // Locked tooltip title is added in _context_module_next.html.erb
  if (progression_state !== 'locked' && progression_state !== 'unlocked') {
    $module.find('.completion_status i:visible').attr('title', progression_state_capitalized)
  }

  if (progression_state === 'completed' && !$module.find('.progression_requirement').length) {
    // this means that there were no requirements so even though the workflow_state says completed, dont show "completed" because there really wasnt anything to complete
    progression_state = ''
  }
  $module.fillTemplateData({data: {progression_state}})

  let reqs_met = $progression.data('requirements_met')
  if (reqs_met == null) {
    reqs_met = []
  }

  let incomplete_reqs = $progression.data('incomplete_requirements')
  if (incomplete_reqs == null) {
    incomplete_reqs = []
  }

  $module.find('.context_module_item').each(function () {
    const $mod_item = $(this)
    const position = parseInt($mod_item.getTemplateData({textValues: ['position']}).position, 10)
    if (data.current_position && position && data.current_position < position) {
      $mod_item.addClass('after_current_position')
    }
    // set the status icon
    const $icon_container = $mod_item.find('.module-item-status-icon')
    const mod_id = $mod_item.getTemplateData({textValues: ['id']}).id

    const completed = some(
      reqs_met,
      // eslint-disable-next-line eqeqeq
      req => req.id == mod_id && $mod_item.hasClass(req.type + '_requirement')
    )
    if (completed) {
      $mod_item.addClass('completed_item')
      addIcon($icon_container, 'icon-check', I18n.t('Completed'))
    } else if (progression_state === 'completed') {
      // if it's already completed then don't worry about warnings, etc
      if ($mod_item.hasClass('progression_requirement')) {
        addIcon($icon_container, 'no-icon', I18n.t('Not completed'))
      }
    } else if ($mod_item.data('past_due') != null) {
      addIcon($icon_container, 'icon-minimize', I18n.t('This assignment is overdue'))
    } else {
      let incomplete_req = null
      for (const idx in incomplete_reqs) {
        // eslint-disable-next-line eqeqeq
        if (incomplete_reqs[idx].id == mod_id) {
          incomplete_req = incomplete_reqs[idx]
        }
      }
      if (incomplete_req) {
        if (incomplete_req.score != null) {
          // didn't score high enough
          addIcon(
            $icon_container,
            'icon-minimize',
            I18n.t('You scored a %{score}.', {score: incomplete_req.score}) +
              ' ' +
              criterionMessage($mod_item) +
              '.'
          )
        } else {
          // hasn't been scored yet
          addIcon($icon_container, 'icon-info', I18n.t('Your submission has not been graded yet'))
        }
      } else if ($mod_item.hasClass('progression_requirement')) {
        addIcon($icon_container, 'icon-mark-as-read', criterionMessage($mod_item))
      }
    }
  })
  if (data.collapsed === 'true') {
    $module.addClass('collapsed_module')
  }
}

export function itemContentKey(model) {
  if (model === null) return null

  const attrs = model.attributes || model
  let content_type = underscoreString(attrs.module_type || attrs.type)
  let content_id = attrs.content_id || attrs.id

  content_type = content_type_map[content_type] || content_type

  if (!content_type || content_type === 'module') {
    return null
  } else {
    if (content_type === 'wiki_page') {
      content_type = 'wiki_page'
      content_id = attrs.page_url || attrs.id
    } else if (
      content_type === 'context_module_sub_header' ||
      content_type === 'external_url' ||
      content_type === 'context_external_tool'
    ) {
      content_id = attrs.id
    }

    let result = content_type + '_' + content_id
    // moduleItems has differing keys for lti-quiz items depending on whether the module has been recently added
    // to the DOM or whether it was there on page load. Here we add both keys to the list of keys to check for each
    // iteration.
    if (attrs.quiz_lti) {
      result = [result, 'lti-quiz_' + content_id]
    }
    return result
  }
}

export function updateModuleItem(moduleItems, attrs, model) {
  let i, item, parsedAttrs
  const itemContentKeys = itemContentKey(attrs) || itemContentKey(model)
  let items = []
  // If the itemContentKeys is an array, we need to iterate over each key and concat the items together. This is because
  // moduleItems has multiple keys for lti-quiz items depending on whether the module has been recently added to the DOM
  // or whether it was there on page load.
  if (Array.isArray(itemContentKeys)) {
    items = itemContentKeys
      .map(key => moduleItems[key])
      .filter(mitem => mitem !== undefined)
      .flat(1)
  } else {
    items = moduleItems[itemContentKeys]
  }

  if (items) {
    for (i = 0; i < items.length; i++) {
      item = items[i]
      parsedAttrs = item.model.parse(attrs)

      if (parsedAttrs.type === 'File' || model.attributes.type === 'file') {
        const locked =
          'published' in parsedAttrs ? !parsedAttrs.published : item.model.get('locked')
        item.model.set({locked, disabled: parsedAttrs.bulkPublishInFlight})
      } else {
        const published =
          'published' in parsedAttrs ? parsedAttrs.published : item.model.get('published')
        item.model.set({published, bulkPublishInFlight: parsedAttrs.bulkPublishInFlight})
      }
      item.model.view.render()
    }
  }
}

export function overrideModuleModel(moduleItems, relock_modules_dialog, model) {
  const publish = model.publish,
    unpublish = model.unpublish
  model.publish = function () {
    return publish.apply(model, arguments).done(data => {
      if (data.publish_warning) {
        $.flashWarning(I18n.t('Some module items could not be published'))
      }

      relock_modules_dialog.renderIfNeeded(data)
      model.fetch({data: {include: 'items'}}).done(attrs => {
        for (let i = 0; i < attrs.items.length; i++)
          updateModuleItem(moduleItems, attrs.items[i], model)
      })
    })
  }
  model.unpublish = function () {
    return unpublish.apply(model, arguments).done(() => {
      model.fetch({data: {include: 'items'}}).done(attrs => {
        for (let i = 0; i < attrs.items.length; i++)
          updateModuleItem(moduleItems, attrs.items[i], model)
      })
    })
  }
}

export function overrideItemModel(moduleItems, model) {
  const publish = model.publish,
    unpublish = model.unpublish
  model.publish = function () {
    return publish.apply(model, arguments).done(attrs => {
      updateModuleItem(moduleItems, $.extend({published: true}, attrs), model)
    })
  }
  model.unpublish = function () {
    return unpublish.apply(model, arguments).done(attrs => {
      updateModuleItem(moduleItems, $.extend({published: false}, attrs), model)
    })
  }
}

export function overrideModel(moduleItems, relock_modules_dialog, model, view) {
  const contentKey = itemContentKey(model)
  if (contentKey === null) overrideModuleModel(moduleItems, relock_modules_dialog, model)
  else overrideItemModel(moduleItems, model)

  moduleItems[contentKey] || (moduleItems[contentKey] = [])
  moduleItems[contentKey].push({model, view})
}

export function openExternalTool(ev) {
  if (ev != null) {
    ev.preventDefault()
  }
  const launchType = ev.target.dataset.toolLaunchType
  // modal placements use ExternalToolModalLauncher which expects a tool in the launch_definition format
  const idAttribute = launchType.includes('modal') ? 'definition_id' : 'id'
  const tool = findToolFromEvent(ENV.MODULE_TOOLS[launchType], idAttribute, ev)

  const currentModule = $(ev.target).parents('.context_module')
  const currentModuleId =
    currentModule.length > 0 && currentModule.attr('id').substring('context_module_'.length)

  if (launchType === 'module_index_menu_modal') {
    setExternalToolModal({tool, launchType, returnFocusTo: $('.al-trigger')[0]})
    return
  }

  if (launchType === 'module_menu_modal') {
    setExternalToolModal({
      tool,
      launchType,
      returnFocusTo: $('.al-trigger')[0],
      contextModuleId: currentModuleId,
    })
    return
  }

  const moduleData = []
  if (launchType === 'module_index_menu') {
    // include all modules
    moduleData.push({
      course_id: ENV.COURSE_ID,
      type: 'module',
    })
  } else if (launchType === 'module_group_menu') {
    // just include the one module whose menu we're on
    moduleData.push({
      id: currentModuleId,
      name: currentModule.find('.name').attr('title'),
    })
  }
  setExternalToolTray(tool, moduleData, launchType, $('.al-trigger')[0])
}

function setExternalToolTray(tool, moduleData, placement = 'module_index_menu', returnFocusTo) {
  const handleDismiss = () => {
    setExternalToolTray(null)
    returnFocusTo.focus()
    if (ltiState?.tray?.refreshOnClose) {
      window.location.reload()
    }
  }

  ReactDOM.render(
    <ContentTypeExternalToolTray
      tool={tool}
      placement={placement}
      acceptedResourceTypes={[
        'assignment',
        'audio',
        'discussion_topic',
        'document',
        'image',
        'module',
        'quiz',
        'page',
        'video',
      ]}
      targetResourceType="module"
      allowItemSelection={placement === 'module_index_menu'}
      selectableItems={moduleData}
      onDismiss={handleDismiss}
      open={tool !== null}
    />,
    $('#external-tool-mount-point')[0]
  )
}

function setExternalToolModal({
  tool,
  launchType,
  returnFocusTo,
  isOpen = true,
  contextModuleId = null,
}) {
  if (isOpen) {
    addDeepLinkingListener(() => {
      window.location.reload()
    })
  }

  const handleDismiss = () => {
    setExternalToolModal({tool, launchType, returnFocusTo, contextModuleId, isOpen: false})
    returnFocusTo.focus()
  }

  ReactDOM.render(
    <ExternalToolModalLauncher
      tool={tool}
      launchType={launchType}
      isOpen={isOpen}
      contextType="course"
      contextId={parseInt(ENV.COURSE_ID, 10)}
      title={tool.name}
      onRequestClose={handleDismiss}
      contextModuleId={contextModuleId}
    />,
    $('#external-tool-mount-point')[0]
  )
}

function findToolFromEvent(collection, idAttribute, event) {
  return (collection || []).find(t => t[idAttribute] === event.target.dataset.toolId)
}
