/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, {Component} from 'react'
import {func, object, instanceOf} from 'prop-types'
import ReactDOM from 'react-dom'
import I18n from 'i18n!outcomes'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Text from '@instructure/ui-core/lib/components/Text'

export function showOutcomesImporter (props) {
  ReactDOM.render(<OutcomesImporter {...props}/>, props.mount)
}

export default class OutcomesImporter extends Component {
  static propTypes = {
    mount: instanceOf(Element).isRequired,
    disableOutcomeViews: func.isRequired,
    resetOutcomeViews: func.isRequired,
    file: object.isRequired
  }

  componentDidMount () {
    this.beginUpload()
  }

  beginUpload () {
    const {disableOutcomeViews} = this.props
    disableOutcomeViews()
    setTimeout(() => {
        this.completeUpload()
    }, 3000)
  }

  completeUpload () {
    const {mount, resetOutcomeViews} = this.props
    if (mount) ReactDOM.unmountComponentAtNode(mount)
    resetOutcomeViews()
  }

  render () {
    const styles = {
      'textAlign': 'center',
      'marginTop': '3rem'
    }
    return (
      <div style={styles}>
        <Spinner
          title = {I18n.t('importing outcomes')}
          size = 'large'
        />
        <Heading level='h4'>
          {I18n.t("Please wait as we upload and process your file.")}
        </Heading>
        <Text fontStyle='italic'>
          {I18n.t("It's ok to leave this page and return later, we'll keep working on it.")}
        </Text>
      </div>
    )
  }
}