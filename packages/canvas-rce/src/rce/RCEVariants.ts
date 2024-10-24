/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import formatMessage from '../format-message'

type MenuBarSpec = string
// copied from node_modules/tinymce/tinymce.d.ts:1434
type MenusSpec = Record<
  string,
  {
    title: string
    items: string
  }
>
// copied from node_modules/tinymce/tinymce.d.ts:1187
interface ToolbarGroupSetting {
  name: string
  items: string[]
}

type StatusBarFeature =
  | 'ai_tools'
  | 'keyboard_shortcuts'
  | 'a11y_checker'
  | 'word_count'
  | 'html_view'
  | 'fullscreen'
  | 'resize_handle'

export const RCEVariantValues = ['full', 'lite', 'text-only', 'text-block'] as const

export type RCEVariant = (typeof RCEVariantValues)[number]

export function getMenubarForVariant(variant: RCEVariant): MenuBarSpec {
  if (variant === 'full') {
    return 'edit view insert format tools table'
  }
  return ''
}

export function getMenuForVariant(variant: RCEVariant): MenusSpec {
  if (variant === 'full') {
    return {
      edit: {
        title: formatMessage('Edit'),
        items: `undo redo | cut copy paste | selectall`,
      },
      format: {
        title: formatMessage('Format'),
        items:
          'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align directionality | forecolor backcolor | removeformat',
      },
      insert: {
        title: formatMessage('Insert'),
        items:
          'instructure_links instructure_image instructure_media instructure_document instructure_icon_maker | instructure_equation inserttable instructure_media_embed | hr',
      },
      tools: {
        title: formatMessage('Tools'),
        items: 'instructure_wordcount lti_tools_menuitem instructure_search_and_replace',
      },
      view: {
        title: formatMessage('View'),
        items: 'instructure_fullscreen instructure_exit_fullscreen instructure_html_view',
      },
    }
  }
  return {}
}

export function getToolbarForVariant(
  variant: RCEVariant,
  ltiToolFavorites: string[] = []
): ToolbarGroupSetting[] {
  if (variant === 'lite') {
    return [
      {
        name: formatMessage('Styles'),
        items: ['formatselect'],
      },
      {
        name: formatMessage('Formatting'),
        items: ['bold', 'italic', 'underline', 'forecolor'],
      },
      {
        name: formatMessage('Content'),
        items: ['instructure_links', 'instructure_image'],
      },
      {
        name: formatMessage('Lists'),
        items: ['bullist'],
      },
      {
        name: formatMessage('Miscellaneous'),
        items: ['instructure_equation'],
      },
    ]
  }

  if (variant === 'text-only') {
    return [
      {
        name: formatMessage('Formatting'),
        items: ['bold', 'italic', 'underline'],
      },
      {
        name: formatMessage('Content'),
        items: ['instructure_links'],
      },
    ]
  }

  if (variant === 'text-block') {
    return [
      {
        name: formatMessage('Styles'),
        items: ['fontsizeselect', 'formatselect'],
      },
      {
        name: formatMessage('Formatting'),
        items: [
          'bold',
          'italic',
          'underline',
          'forecolor',
          'backcolor',
          'inst_subscript',
          'inst_superscript',
        ],
      },
      {
        name: formatMessage('Content'),
        items: ['instructure_links', 'instructure_documents'],
      },
      {
        name: formatMessage('Alignment and Lists'),
        items: ['align', 'bullist', 'inst_indent', 'inst_outdent'],
      },
      {
        name: formatMessage('Miscellaneous'),
        items: ['removeformat', 'instructure_equation'],
      },
    ]
  }

  return [
    {
      name: formatMessage('Styles'),
      items: ['fontsizeselect', 'formatselect'],
    },
    {
      name: formatMessage('Formatting'),
      items: [
        'bold',
        'italic',
        'underline',
        'forecolor',
        'backcolor',
        'inst_subscript',
        'inst_superscript',
      ],
    },
    {
      name: formatMessage('Content'),
      items: [
        'instructure_links',
        'instructure_image',
        'instructure_record',
        'instructure_documents',
        'instructure_icon_maker',
      ],
    },
    {
      name: formatMessage('External Tools'),
      items: [...ltiToolFavorites, 'lti_tool_dropdown', 'lti_mru_button'],
    },
    {
      name: formatMessage('Alignment and Lists'),
      items: ['align', 'bullist', 'inst_indent', 'inst_outdent'],
    },
    {
      name: formatMessage('Miscellaneous'),
      items: ['removeformat', 'table', 'instructure_equation', 'instructure_media_embed'],
    },
  ]
}

export function getStatusBarFeaturesForVariant(
  variant: RCEVariant,
  ai_text_tools: boolean = false
): StatusBarFeature[] {
  if (variant === 'lite' || variant === 'text-only') {
    return ['keyboard_shortcuts', 'a11y_checker', 'word_count']
  }
  if (variant === 'text-block') {
    return []
  }

  const full_features: StatusBarFeature[] = [
    'keyboard_shortcuts',
    'a11y_checker',
    'word_count',
    'html_view',
    'fullscreen',
    'resize_handle',
  ]
  if (ai_text_tools) {
    full_features.push('ai_tools')
  }
  return full_features
}
