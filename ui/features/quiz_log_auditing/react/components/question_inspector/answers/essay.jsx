/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import Button from '../../button'
import {useScope as useI18nScope} from '@canvas/i18n'
import K from '../../../../constants'
import React from 'react'

const I18n = useI18nScope('quiz_log_auditing.question_answers.essay')

class Essay extends React.Component {
  static defaultProps = {
    answer: '',
  }

  state = {
    htmlView: false,
  }

  render() {
    let content

    if (this.state.htmlView) {
      content = <div dangerouslySetInnerHTML={{__html: this.props.answer}} />
    } else {
      content = <pre>{this.props.answer}</pre>
    }

    return (
      <div>
        {content}

        <Button type="default" onClick={this.toggleView.bind(this)}>
          {this.state.htmlView
            ? I18n.t('view_plain_answer', 'View Plain')
            : I18n.t('view_html_answer', 'View HTML')}
        </Button>
      </div>
    )
  }

  toggleView() {
    this.setState(state => ({htmlView: !state.htmlView}))
  }
}

Essay.questionTypes = [K.Q_ESSAY]

export default Essay
