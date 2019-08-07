/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import axios from 'axios'
import I18n from 'i18n!DefaultToolForm'
import PropTypes from 'prop-types';
import React, {useState, useEffect} from 'react'

import SelectContentDialog from '../../../public/javascripts/select_content_dialog.js'

import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-layout'

const DefaultToolForm = props => {
  const [launchDefinitions, setLaunchDefinitions] = useState([])

  const defaultToolData = launchDefinitions.find(definition =>
    Object.values(definition.placements).find(placement => placement.url === props.toolUrl)
  )

  const launchDefinitionUrl = () =>
    `/api/v1/courses/${props.courseId}/lti_apps/launch_definitions?per_page=100&placements%5B%5D=assignment_selection&placements%5B%5D=resource_selection`

  useEffect(() => {
    const fetchData = async () => {
      const result = await axios.get(launchDefinitionUrl())
      setLaunchDefinitions(result.data)
    }
    fetchData()
  }, [])

  useEffect(() => {
    $('#default-tool').data('tool', defaultToolData)
  }, [launchDefinitions])

  const handleLaunchButton = event => {
    SelectContentDialog.Events.onContextExternalToolSelect(event, $('#default-tool'))
  }

  return (
    <View display="block" padding="medium none small small">
      <Button id="default-tool-launch-button" onClick={handleLaunchButton}>
        {I18n.t('Add a Question Set')}
      </Button>
      <Alert variant="info" renderCloseButtonLabel="Close" margin="small small 0 0">
        {I18n.t('Click the button above to add a WileyPLUS Question Set')}
      </Alert>
      {defaultToolData && (
        <div style={{display: 'none'}}>
          <ul className="tools">
            <li id="default-tool" className="tool resource_selection">
              <a href="#" className="name">
                {defaultToolData.name}
              </a>
              <div className="description">This is a Sample Tool Provider.</div>
            </li>
          </ul>
        </div>
      )}
    </View>
  )
}

DefaultToolForm.propTypes = {
  toolUrl: PropTypes.string.isRequired,
  courseId: PropTypes.number.isRequired
}

export default DefaultToolForm
