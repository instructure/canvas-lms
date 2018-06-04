/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!react_files'
import $ from 'jquery'

export default function deleteStuff(filesAndFolders, args) {
  const isDeletingAnUnemptyFolder = filesAndFolders.some(
    item => item.get('folders_count') || item.get('files_count')
  )
  const message = isDeletingAnUnemptyFolder
    ? I18n.t(
        'confirm_delete_with_contents',
        {
          one:
            'Are you sure you want to delete %{name}? It is not empty, anything inside it will be deleted too.',
          other: 'Are you sure you want to delete these %{count} items and everything inside them?'
        },
        {
          count: filesAndFolders.length,
          name: filesAndFolders[0] && filesAndFolders[0].displayName()
        }
      )
    : I18n.t(
        {
          one: 'Are you sure you want to delete %{name}?',
          other: 'Are you sure you want to delete these %{count} items?'
        },
        {
          count: filesAndFolders.length,
          name: filesAndFolders[0] && filesAndFolders[0].displayName()
        }
      )
  if (!confirm(message)) return

  const promises = filesAndFolders.map(item =>
    item.destroy({
      emulateHTTP: true,
      emulateJSON: true,
      data: {
        force: 'true'
      },
      wait: true,
      error(model, response, options) {
        const reason = (() => {
          try {
            const json = $.parseJSON(response.responseText)
            return json && json.message
          } catch (error) {}
        })()

        return $.flashError(
          I18n.t('Error deleting %{name}: %{reason}', {
            name: item.displayName(),
            reason
          })
        )
      }
    })
  )

  return $.when(...Array.from(promises || [])).then(function() {
    $.flashMessage(
      I18n.t(
        {
          one: '%{name} deleted successfully.',
          other: '%{count} items deleted successfully.'
        },
        {
          count: filesAndFolders.length,
          name: filesAndFolders[0] && filesAndFolders[0].displayName()
        }
      )
    )
    if (args && args.returnFocusTo) {
      $(args.returnFocusTo).focus()
    }
  })
}
