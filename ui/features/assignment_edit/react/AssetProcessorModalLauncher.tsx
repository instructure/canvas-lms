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
import {DeepLinkResponse} from '@canvas/deep-linking/DeepLinkResponse';
import {AssetProcessorContentItem} from '@canvas/deep-linking/models/AssetProcessorContentItem';
import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog';

export function AssetProcessorModalLauncher({secureParams}: {secureParams: string}) {
  const [isOpen, setIsOpen] = useState(false);
  const [tools, setTools] = useState<LtiLaunchDefinition[]>([]);
  const [selectedTool, setSelectedTool] = useState<LtiLaunchDefinition|null>(null);
  // TODO: currently does not allow for multiple APs to be attached from the same tool unless they are part of the same deep linking response
  const [formData, setFormData] = useState<Record<string, AssetProcessorContentItem[]>>({})

  function handleDeepLinkingResponse(data: DeepLinkResponse) {
    const toolId = data.tool_id!.toString()
    setFormData(
      prevState => ({
        ...prevState,
        [toolId]: data.content_items.filter(item => item.type === 'ltiAssetProcessor')
      })
    )
    setIsOpen(false)
  }

  function getDefinitionsUrl(courseId: number) {
    return `/api/v1/courses/${courseId}/lti_apps/launch_definitions`
  }

  useEffect(() => {
    const course_id = parseInt(ENV.COURSE_ID!, 10)
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

  const handleButtonClick = (tool: LtiLaunchDefinition) => {
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
          tool={selectedTool}
          isOpen={isOpen}
          onRequestClose={() => setIsOpen(false)}
          contextType={"course"}
          contextId={parseInt(ENV.COURSE_ID!, 10)}
          launchType="ActivityAssetProcessor"
          title={`Deep Link AP - ${selectedTool.name}`}
          resourceSelection
          onDeepLinkingResponse={handleDeepLinkingResponse}
          secureParams={secureParams}
        />
      )}
      {Object.keys(formData).map((toolId, toolIndex) => (
        formData[toolId].map((item, index) => (
          <div key={`${toolId}-${index}`}>
            <input data-testid={`asset_processors[${toolIndex}][${index}][url]`} type="hidden" name={`asset_processors[${toolIndex}][${index}][url]`} value={item.url} />
            <input type="hidden" name={`asset_processors[${toolIndex}][${index}][title]`} value={item.title} />
            <input type="hidden" name={`asset_processors[${toolIndex}][${index}][text]`} value={item.text} />
            <input type="hidden" name={`asset_processors[${toolIndex}][${index}][custom]`} value={JSON.stringify(item.custom)} />
            <input type="hidden" name={`asset_processors[${toolIndex}][${index}][icon]`} value={JSON.stringify(item.icon)} />
            <input type="hidden" name={`asset_processors[${toolIndex}][${index}][window]`} value={JSON.stringify(item.window)} />
            <input type="hidden" name={`asset_processors[${toolIndex}][${index}][iframe]`} value={JSON.stringify(item.iframe)} />
            <input type="hidden" name={`asset_processors[${toolIndex}][${index}][report]`} value={JSON.stringify(item.report)} />
            <input type="hidden" name={`asset_processors[${toolIndex}][${index}][context_external_tool_id]`} value={toolId} />
          </div>
        ))
      ))}
    </div>
  );
}

export const attach = function ({container, secureParams}: {container: HTMLElement, secureParams: string}) {
  const root = createRoot(container)
  root.render(<AssetProcessorModalLauncher secureParams={secureParams} />)
}
