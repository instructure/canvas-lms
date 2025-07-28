/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {SettingsPanelState} from '../react/settingsReducer'
import type {Module, Requirement} from '../react/types'
import {updateModulePublishedState} from '../../utils/publishAllModulesHelper'
import {datetimeString} from '@canvas/datetime/date-functions'
import {convertFriendlyDatetimeToUTC} from './miscHelpers'
import {isModuleCollapsed, isModulePaginated} from '@canvas/context-modules/utils/showAllOrLess'
import {fetchItemTitles} from '@canvas/context-modules/utils/fetchItemTitles'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('differentiated_modules')

const resourceTypeMap: Record<string, Requirement['resource']> = {
  assignment: 'assignment',
  quiz: 'quiz',
  attachment: 'file',
  wiki_page: 'page',
  discussion_topic: 'discussion',
  external_url: 'externalUrl',
  context_external_tool: 'externalTool',
  'lti-quiz': 'quiz',
}

const requirementTypeMap: Record<string, Requirement['type']> = {
  min_score_requirement: 'score',
  min_percentage_requirement: 'percentage',
  must_view_requirement: 'view',
  must_mark_done_requirement: 'mark',
  must_contribute_requirement: 'contribute',
  must_submit_requirement: 'submit',
}

const requirementTypeMapReverse: Record<Requirement['type'], string> = {
  score: 'min_score_requirement',
  percentage: 'min_percentage_requirement',
  view: 'must_view_requirement',
  mark: 'must_mark_done_requirement',
  contribute: 'must_contribute_requirement',
  submit: 'must_submit_requirement',
}

const requirementFriendlyLabelMap: Record<Requirement['type'], string> = {
  score: I18n.t('Score at least'),
  percentage: I18n.t('Score at least'),
  view: I18n.t('View'),
  mark: I18n.t('Mark done'),
  contribute: I18n.t('Contribute'),
  submit: I18n.t('Submit'),
}

function requirementScreenreaderMessage(requirement: Requirement) {
  switch (requirement.type) {
    case 'score':
      return I18n.t('Must score at least %{points} to complete this module item', {
        points: requirement.minimumScore,
      })
    case 'view':
      return I18n.t('Must view in order to complete this module item')
    case 'mark':
      return I18n.t('Must mark this module item done in order to complete')
    case 'contribute':
      return I18n.t('Must contribute to this module item to complete it')
    case 'submit':
      return I18n.t('Must submit this module item to complete it')
    case 'percentage':
      return I18n.t('Must score at least %{points}% to complete this module item', {
        points: requirement.minimumScore,
      })
  }
}

export async function parseModule(element: HTMLDivElement) {
  const moduleId = element.getAttribute('data-module-id')
  const moduleName = element.querySelector('.name')?.getAttribute('title') ?? ''
  const unlockAt = convertFriendlyDatetimeToUTC(element.querySelector('.unlock_at')?.textContent)
  const requirementCount =
    element.querySelector('.requirements_message')?.getAttribute('data-requirement-type') ?? 'all'
  const requireSequentialProgress =
    element.querySelector('.require_sequential_progress')?.textContent === 'true'
  const publishFinalGrade = element.querySelector('.publish_final_grade')?.textContent === 'true'
  const prerequisites = parsePrerequisites(element)
  const moduleList = parseModuleList()
  const requirements = parseRequirements(element)
  const moduleItems = await parseModuleItems(element)

  return {
    moduleId,
    moduleName,
    unlockAt,
    requirementCount,
    requireSequentialProgress,
    publishFinalGrade,
    prerequisites,
    moduleList,
    requirements,
    moduleItems,
  }
}

function parsePrerequisites(element: HTMLDivElement) {
  return Array.from(element.querySelectorAll('.prerequisite_criterion')).map(prerequisite => {
    return {
      id: prerequisite.querySelector('.id')?.textContent ?? '',
      name: prerequisite.querySelector('.name')?.textContent ?? '',
    }
  })
}

export function parseModuleList() {
  const potentialModules = Array.from(
    document.querySelectorAll('.item-group-condensed.context_module.editable_context_module'),
  )
  const parsedModules = potentialModules.reduce((moduleList: Module[], moduleNode: Element) => {
    const id = moduleNode.getAttribute('data-module-id') ?? ''
    const name = moduleNode.getAttribute('aria-label')
    if (!Number.isNaN(parseInt(id, 10)) && name) {
      moduleList.push({id, name})
    }
    return moduleList
  }, [])
  return parsedModules
}

function parseRequirements(element: HTMLDivElement) {
  const requirementElements = Array.from(
    element.querySelectorAll('.ig-row.with-completion-requirements'),
  )
  return requirementElements.map((requirementNode: Element) =>
    parseModuleItemData(requirementNode, true),
  ) as Requirement[]
}

async function parseModuleItems(element: HTMLDivElement) {
  if (ENV.FEATURE_MODULES_PERF && (isModuleCollapsed(element) || isModulePaginated(element))) {
    const moduleId = element.getAttribute('data-module-id')
    const courseId = ENV.COURSE_ID
    if (!moduleId || !courseId) return []
    const items = await fetchItemTitles(courseId, moduleId, ['type'])
    return items.map((item: any) => ({
      id: item.id,
      name: item.title,
      resource: resourceTypeMap[item.type],
    }))
  } else {
    const moduleItemElements = Array.from(element.querySelectorAll('.ig-row'))
    return moduleItemElements.map(moduleItem => parseModuleItemData(moduleItem, false))
  }
}

export function updateModuleUI(moduleElement: HTMLDivElement, moduleSettings: SettingsPanelState) {
  ;[
    updateName,
    updateUnlockTime,
    updatePrerequisites,
    updateRequirements,
    updatePublishFinalGrade,
  ].forEach(fn => fn(moduleElement, moduleSettings))
}

function updateName(moduleElement: HTMLDivElement, moduleSettings: SettingsPanelState) {
  // Update other modules' prerequisites if they refer to this module
  // Must be done before we update the old name to the new name below
  const oldModuleName = moduleElement.getAttribute('aria-label')
  if (oldModuleName && oldModuleName !== moduleSettings.moduleName) {
    // Update the visible pieces that users see
    document.querySelectorAll('.prerequisites_message').forEach(messageElement => {
      if (messageElement.textContent?.includes(oldModuleName)) {
        messageElement.textContent = messageElement.textContent.replace(
          oldModuleName,
          moduleSettings.moduleName,
        )
      }
    })

    // Update the hidden piece that is used for parsing when opening the tray
    document.querySelectorAll('.prerequisite_criterion > .name').forEach(nameElement => {
      if (nameElement.textContent === oldModuleName) {
        nameElement.textContent = moduleSettings.moduleName
      }
    })
  }

  moduleElement.setAttribute('aria-label', moduleSettings.moduleName)

  const screenreaderOnlyElement = moduleElement.querySelector('.screenreader-only')
  if (screenreaderOnlyElement) {
    screenreaderOnlyElement.textContent = moduleSettings.moduleName
  }

  moduleElement.querySelectorAll('.name').forEach(nameElement => {
    nameElement.setAttribute('title', moduleSettings.moduleName)
    nameElement.textContent = moduleSettings.moduleName
  })

  moduleElement.querySelectorAll('.collapse_module_link, .expand_module_link').forEach(button => {
    button.setAttribute('title', moduleSettings.moduleName)
    button.setAttribute(
      'aria-label',
      I18n.t('%{name} toggle module visibility', {name: moduleSettings.moduleName}),
    )
  })

  const addModuleItemButton = moduleElement.querySelector('.add_module_item_link')
  if (addModuleItemButton) {
    const message = I18n.t('Add Content to %{name}', {name: moduleSettings.moduleName})
    addModuleItemButton.setAttribute('aria-label', message)

    const innerScreenreaderOnlyElement = addModuleItemButton.querySelector('.screenreader-only')
    if (innerScreenreaderOnlyElement) {
      innerScreenreaderOnlyElement.textContent = message
    }
  }

  const kebabMenuButton = moduleElement.querySelector('.Button--icon-action.al-trigger')
  if (kebabMenuButton) {
    kebabMenuButton.setAttribute(
      'aria-label',
      I18n.t('Manage %{name}', {name: moduleSettings.moduleName}),
    )
  }

  const duplicateButton = moduleElement.querySelector('.duplicate_module_link')
  if (duplicateButton) {
    duplicateButton.setAttribute(
      'aria-label',
      I18n.t('Duplicate %{name}', {name: moduleSettings.moduleName}),
    )
  }

  const moduleId = moduleElement.getAttribute('data-module-id')
  if (moduleId) {
    const published = moduleElement.getAttribute('data-workflow-state') === 'active'
    updateModulePublishedState(parseInt(moduleId, 10), published, false)
  }
}

function updateUnlockTime(moduleElement: HTMLDivElement, moduleSettings: SettingsPanelState) {
  const friendlyDatetime = moduleSettings.lockUntilChecked
    ? datetimeString(moduleSettings.unlockAt)
    : ''

  const unlockAtElement = moduleElement.querySelector('.unlock_at')
  if (unlockAtElement) {
    unlockAtElement.textContent = friendlyDatetime
  }

  const displayedUnlockAtElement = moduleElement.querySelector('.displayed_unlock_at')
  if (displayedUnlockAtElement) {
    displayedUnlockAtElement.textContent = friendlyDatetime
    displayedUnlockAtElement.setAttribute('data-html-tooltip-title', friendlyDatetime)
  }

  const unlockDetailsElement = moduleElement.querySelector('.unlock_details') as HTMLDivElement
  if (unlockDetailsElement) {
    // User has selected a lock date and that date is in the future
    if (moduleSettings.lockUntilChecked && new Date(moduleSettings.unlockAt) > new Date()) {
      unlockDetailsElement.style.display = ''
    } else {
      unlockDetailsElement.style.display = 'none'
    }
  }
}

function updatePrerequisites(moduleElement: HTMLDivElement, moduleSettings: SettingsPanelState) {
  const prerequisiteElement = moduleElement.querySelector('.prerequisites')
  if (prerequisiteElement) {
    // Clear everything out so we can start fresh
    prerequisiteElement.innerHTML = ''

    if (moduleSettings.prerequisites.length === 0) return

    // For parsing when opening the tray
    // Would love to simplify this, but we need backwards compatitibility
    moduleSettings.prerequisites.forEach(prerequisite => {
      const div = document.createElement('div')
      div.classList.add(...['prerequisite_criterion', 'context_module_criterion'])
      div.style.float = 'left'

      const idSpan = document.createElement('span')
      idSpan.className = 'id'
      idSpan.style.display = 'none'
      idSpan.textContent = prerequisite.id

      const typeSpan = document.createElement('span')
      typeSpan.className = 'type'
      typeSpan.style.display = 'none'
      typeSpan.textContent = 'context_module'

      const nameSpan = document.createElement('span')
      nameSpan.className = 'name'
      nameSpan.style.display = 'none'
      nameSpan.title = moduleSettings.moduleName
      nameSpan.textContent = prerequisite.name

      div.appendChild(idSpan)
      div.appendChild(typeSpan)
      div.appendChild(nameSpan)

      prerequisiteElement.appendChild(div)
    })

    const prereqMessageElement =
      moduleElement.querySelector('.prerequisites_message') || document.createElement('div')
    prereqMessageElement.classList.add('prerequisites_message')
    prereqMessageElement.textContent = I18n.t('Prerequisites: %{names}', {
      names: moduleSettings.prerequisites.map(prerequisite => prerequisite.name).join(', '),
    })
    prerequisiteElement.appendChild(prereqMessageElement)
  }
}

function updateRequirements(moduleElement: HTMLDivElement, moduleSettings: SettingsPanelState) {
  const requirementsMessageElement = moduleElement.querySelector('.requirements_message')
  if (requirementsMessageElement) {
    requirementsMessageElement.setAttribute(
      'data-requirement-type',
      moduleSettings.requirementCount,
    )

    if (moduleSettings.requirements.length === 0) {
      requirementsMessageElement.innerHTML = ``
    } else {
      const requirementText =
        moduleSettings.requirementCount === 'all' ? 'Complete All Items' : 'Complete One Item'
      requirementsMessageElement.innerHTML = `
        <ul class="pill">
          <li aria-label="${requirementText}">${requirementText}</li>
        </ul>
      `
    }
  }

  const sequentialProgressElement = moduleElement.querySelector('.require_sequential_progress')
  if (sequentialProgressElement) {
    sequentialProgressElement.textContent = moduleSettings.requireSequentialProgress.toString()
  }

  // Clear everything out so we can start with a fresh slate
  moduleElement.querySelectorAll('.ig-row').forEach(item => {
    item.classList.remove('with-completion-requirements')
    const descriptionElement = item.querySelector('.requirement-description')
    if (descriptionElement) {
      descriptionElement.innerHTML = ''
    }
  })

  moduleSettings.requirements.forEach(requirement => {
    const moduleItemElement = moduleElement.querySelector(`#context_module_item_${requirement.id}`)
    if (moduleItemElement) {
      moduleItemElement.querySelector('.ig-row')?.classList.add('with-completion-requirements')

      const descriptionElement = moduleItemElement.querySelector('.requirement-description')
      if (descriptionElement) {
        const scoreElement =
          requirement.type === 'score' || requirement.type === 'percentage'
            ? `<span class="min_score"> ${requirement.minimumScore}</span>`
            : ''

        const percentageSymbol = requirement.type === 'percentage' ? '%' : ''
        descriptionElement.innerHTML = `
          <span class="requirement_type ${requirementTypeMapReverse[requirement.type]}">
            <span class="unfulfilled">
              ${requirementFriendlyLabelMap[requirement.type]}${scoreElement}${percentageSymbol}
              <span class="screenreader-only">${requirementScreenreaderMessage(requirement)}</span>
            </span>
          </span>
        `
      }

      const pointsPossibleElement = moduleItemElement.querySelector('.points_possible_display')
      if (pointsPossibleElement) {
        if (requirement.pointsPossible) {
          pointsPossibleElement.textContent = I18n.t('%{points} pts', {
            points: I18n.n(requirement.pointsPossible),
          })
        } else {
          pointsPossibleElement.textContent = ''
        }
      }
    }
  })
}

function parseModuleItemData(element: Element, isRequirement: boolean) {
  const data = {
    id: element.querySelector('.id')?.textContent,
    name: element.querySelector('.item_name a')?.getAttribute('title')?.trim() || '',
    resource: resourceTypeMap[element.querySelector('.type')?.textContent || 'external_url'],
  }
  let activeRequirementNode
  if (isRequirement) {
    // One of these (the active one) has "display: block;" and the others are hidden
    activeRequirementNode = Array.from(element.querySelectorAll('.requirement_type')).filter(
      node => window.getComputedStyle(node).display !== 'none',
    )[0]
    // @ts-expect-error
    data.type = requirementTypeMap[activeRequirementNode.classList[1] as Requirement['type']]
  }

  if (
    data.resource === 'assignment' ||
    data.resource === 'quiz' ||
    data.resource === 'discussion'
  ) {
    // @ts-expect-error
    data.graded = element.querySelector('.graded')?.textContent === '1'
    const pointsPossibleString = element.querySelector('.points_possible_display')?.textContent
    // @ts-expect-error
    data.pointsPossible = pointsPossibleString ? pointsPossibleString.split(/\s/)[0] : null
    if (isRequirement) {
      // @ts-expect-error
      data.minimumScore =
        activeRequirementNode?.querySelector('.min_score, .min_percentage')?.textContent || '0'
    }
  }
  return data
}

function updatePublishFinalGrade(
  moduleElement: HTMLDivElement,
  moduleSettings: SettingsPanelState,
) {
  const publishFinalGradeElement = moduleElement.querySelector('.publish_final_grade')
  if (publishFinalGradeElement) {
    publishFinalGradeElement.textContent = moduleSettings.publishFinalGrade.toString()
  }
}
