/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'

const I18n = useI18nScope('quizzes.openModerateStudentDialog')

const openModerateStudentDialog = ($dialog, dialogWidth) => {
  const dialog = $dialog
    .dialog({
      title: I18n.t('Student Extensions'),
      width: dialogWidth,
      modal: true,
      zIndex: 1000,
      open() {
        const titleClose = $dialog.parent().find('.ui-dialog-titlebar-close')
        if (titleClose.length) {
          titleClose.trigger('focus')
        }
      },
    })
    .fixDialogButtons()

  return dialog
}

export default openModerateStudentDialog
