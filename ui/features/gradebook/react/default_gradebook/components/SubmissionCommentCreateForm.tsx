// @ts-nocheck
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
import {useScope as useI18nScope} from '@canvas/i18n'
import SubmissionCommentForm from './SubmissionCommentForm'

const I18n = useI18nScope('gradebook')

export default class SubmissionCommentCreateForm extends SubmissionCommentForm {
  static propTypes = {
    ...SubmissionCommentForm.propTypes,
    createSubmissionComment: func.isRequired,
  }

  handleCancel(event) {
    super.handleCancel(event, this.focusTextarea)
  }

  handlePublishComment(event) {
    super.handlePublishComment(event)
    this.setState({comment: ''}, this.focusTextarea)
  }

  buttonLabels() {
    return {
      cancelButtonLabel: I18n.t('Cancel Submitting Comment'),
      submitButtonLabel: I18n.t('Submit Comment'),
    }
  }

  publishComment() {
    return this.props.createSubmissionComment(this.state.comment)
  }

  showButtons() {
    return this.commentIsValid()
  }
}
