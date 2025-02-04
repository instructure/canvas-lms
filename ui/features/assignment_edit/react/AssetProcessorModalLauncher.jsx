/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useEffect, useState} from 'react'
import {createRoot} from 'react-dom/client'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'

export function AssetProcessorModalLauncher() {
  const [isOpen, setIsOpen] = useState(false);
  const [tools, setTools] = useState([]);
  const [selectedTool, setSelectedTool] = useState(null);
  const [formData, setFormData] = useState({});

  function handleDeepLinkingResponse(data) {
    const contentItems = data.content_items.map((item) => ({
        url: item.url,
        title: item.title,
        text: item.text,
        custom: JSON.stringify(item.custom),
        icon: JSON.stringify(item.icon),
        window: JSON.stringify(item.window),
        iframe: JSON.stringify(item.iframe),
        report: JSON.stringify(item.report),
        context_external_tool_id: data.tool_id
      }))
    setFormData(
      prevState => {
        return {...prevState, [data.tool_id]: contentItems};
      }
    )
    setIsOpen(false)
  }

  function getDefinitionsUrl(course_id) {
    return `/api/v1/courses/${course_id}/lti_apps/launch_definitions`
  }

  useEffect(() => {
    const course_id = parseInt(ENV.COURSE_ID, 10)
    const toolsUrl = getDefinitionsUrl(course_id)
    const params = {
      'placements[]': 'ActivityAssetProcessor',
    }

    $.get(toolsUrl, params, (data) => {
      setTools(data)
    })
  }, [])

  if (tools.length === 0) {
    return (<div>Loading...</div>);
  }

  const handleButtonClick = (tool) => {
    setSelectedTool(tool)
    setIsOpen(true)
  }

  return (
    <div>
      <div className="form-column-left">
          Asset Processor [WIP]
      </div>
      <div className="form-column-right">
        <div className="border border-trbl border-round">
          {tools.map((tool, index) => (
            <button
              key={index}
              id="asset-processor"
              type="button"
              style={{ background: 'pink' }}
              onClick={() => handleButtonClick(tool)}
            >
              Attach AP - {tool.name}
            </button>
          ))}
        </div>
      </div>
      {selectedTool && (
        <ExternalToolModalLauncher
          tool={{
            definition_id: selectedTool.definition_id,
          }}
          isOpen={isOpen}
          onRequestClose={() => setIsOpen(false)}
          contextType={"course"}
          contextId={parseInt(ENV.COURSE_ID, 10)}
          launchType="ActivityAssetProcessor"
          title={`Deep Link AP - ${selectedTool.name}`}
          resourceSelection
          onDeepLinkingResponse={handleDeepLinkingResponse}
        />
      )}
      {Object.keys(formData).map((productKey, productIndex) => (
        formData[productKey].map((item, index) => (
          <div key={`${productKey}-${index}`}>
            <input data-testid={`asset_processors[${productIndex}][${index}][url]`} type="hidden" name={`asset_processors[${productIndex}][${index}][url]`} value={item.url} />
            <input type="hidden" name={`asset_processors[${productIndex}][${index}][title]`} value={item.title} />
            <input type="hidden" name={`asset_processors[${productIndex}][${index}][text]`} value={item.text} />
            <input type="hidden" name={`asset_processors[${productIndex}][${index}][custom]`} value={item.custom} />
            <input type="hidden" name={`asset_processors[${productIndex}][${index}][icon]`} value={item.icon} />
            <input type="hidden" name={`asset_processors[${productIndex}][${index}][window]`} value={item.window} />
            <input type="hidden" name={`asset_processors[${productIndex}][${index}][iframe]`} value={item.iframe} />
            <input type="hidden" name={`asset_processors[${productIndex}][${index}][report]`} value={item.report} />
            <input type="hidden" name={`asset_processors[${productIndex}][${index}][context_external_tool_id]`} value={item.context_external_tool_id} />
          </div>
        ))
      ))}
    </div>
  );
}

export const attach = function (element) {
  const root = createRoot(element)
  root.render(<AssetProcessorModalLauncher />)
}