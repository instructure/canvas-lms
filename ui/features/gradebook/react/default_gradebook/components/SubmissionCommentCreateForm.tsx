/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {func} from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import SubmissionCommentForm from './SubmissionCommentForm'
import {Editor} from 'tinymce'
import {ViewProps} from '@instructure/ui-view'

const I18n = createI18nScope('gradebook')

export default class SubmissionCommentCreateForm extends SubmissionCommentForm {
  static propTypes = {
    // @ts-expect-error
    ...SubmissionCommentForm.propTypes,
    createSubmissionComment: func.isRequired,
  }

  initRCE(tinyeditor: Editor) {
    this.tinyeditor = tinyeditor
    if (this.state.rceKey > 0) {
      this.rceRef.current?.focus()
    }
  }

  handleCancel(e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) {
    super.handleCancel(e, this.focusTextarea)
  }

  handlePublishComment(e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) {
    super.handlePublishComment(e)
    this.handleCommentChange('', {rerenderRCE: true, callback: this.focusTextarea})
  }

  buttonLabels() {
    return {
      cancelButtonLabel: I18n.t('Cancel Submitting Comment'),
      submitButtonLabel: I18n.t('Submit Comment'),
    }
  }

  publishComment() {
    // @ts-expect-error
    return this.props.createSubmissionComment(this.state.comment)
  }

  showButtons() {
    return this.commentIsValid()
  }
}
