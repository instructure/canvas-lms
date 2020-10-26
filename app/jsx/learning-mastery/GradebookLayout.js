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
import axios from 'axios'
import I18n from 'i18n!GradebookGrid'
import React from 'react'
import { rollupsUrl } from 'api'

class GradebookLayout extends React.Component {

  componentDidMount() {
    this.loadRollups()
  }

  loadRollups = (page = 1) => {
    const exclude = ''
    const course = ENV.context_asset_string.split('_')[1]
    const url = rollupsUrl(course, exclude, page)
    axios.get(
      url
    ).then((response) => console.log(response))
  }

  render() {
    return <div> Hello World! </div>
  }
}

export default GradebookLayout
