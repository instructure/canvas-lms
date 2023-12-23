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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.instructure_forms'

const I18n = useI18nScope('conditional_release')

const SAVE_TIMEOUT = 15000

class Editor extends React.Component {
  static displayName = 'ConditionalReleaseEditor'

  static propTypes = {
    env: PropTypes.object.isRequired,
    type: PropTypes.string.isRequired,
  }

  state = {
    editor: null,
  }

  validateBeforeSave = () => {
    const errors = []
    const rawErrors = this.state.editor ? this.state.editor.getErrors() : null
    if (rawErrors) {
      rawErrors.forEach(errorRecord => {
        $.screenReaderFlashError(
          I18n.t('%{error} in mastery paths range %{index}', {
            error: errorRecord.error,
            index: errorRecord.index + 1,
          })
        )
        errors.push({message: errorRecord.error})
      })
    }
    return errors.length === 0 ? null : errors
  }

  focusOnError = () => {
    if (this.state.editor) {
      this.state.editor.focusOnError()
    }
  }

  updateAssignment = (newAttributes = {}) => {
    if (!this.state.editor) {
      return
    }
    // a not_graded assignment counts as a non-assignment
    // to cyoe
    if (newAttributes.grading_type === 'not_graded') {
      newAttributes.id = null
    }
    this.state.editor.updateAssignment({
      grading_standard_id: newAttributes.grading_standard_id,
      grading_type: newAttributes.grading_type,
      id: newAttributes.id,
      points_possible: newAttributes.points_possible,
      submission_types: newAttributes.submission_types,
    })
  }

  save = (timeoutMs = SAVE_TIMEOUT) => {
    if (!this.state.editor) {
      return $.Deferred().reject('mastery paths editor uninitialized')
    }
    const saveObject = $.Deferred()
    setTimeout(() => {
      saveObject.reject('timeout')
    }, timeoutMs)

    this.state.editor
      .saveRule()
      .then(() => {
        saveObject.resolve()
      })
      .catch(err => {
        saveObject.reject(err)
      })

    return saveObject.promise()
  }

  loadEditor = () => {
    if (window.conditional_release_module) {
      // spec hook
      return new Promise(resolve =>
        resolve({default: window.conditional_release_module.ConditionalReleaseEditor})
      )
    } else {
      return import('./editor')
    }
  }

  createNativeEditor = () => {
    const env = this.props.env
    return this.loadEditor().then(({default: ConditionalReleaseEditor}) => {
      const editor = new ConditionalReleaseEditor({
        assignment: env.assignment,
        courseId: env.course_id,
      })
      editor.attach(
        document.getElementById('canvas-conditional-release-editor'),
        document.getElementById('application')
      )
      this.setState({editor})
    })
  }

  componentDidMount() {
    this.createNativeEditor()
  }

  render() {
    return <div id="canvas-conditional-release-editor" />
  }
}

const attach = function (element, type, env) {
  const editor = <Editor env={env} type={type} />
  return ReactDOM.render(editor, element)
}

const ConditionalRelease = {
  Editor,
  attach,
}

export default ConditionalRelease
