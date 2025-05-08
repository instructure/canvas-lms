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

// TODO: if editing this file, please consider removing/resolving some of the "any" references

import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import {useScope as createI18nScope} from '@canvas/i18n'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import React from 'react'
import {handleExternalContentMessages} from '../../messages'
import ToolLaunchIframe from './ToolLaunchIframe'
import {onLtiClosePostMessage} from '@canvas/lti/jquery/messages'

const I18n = createI18nScope('external_toolsModalLauncher')

export type ExternalToolModalLauncherProps = {
  appElement: Element
  title: string
  tool: {
    definition_id: string
    placements?: Record<
      string,
      {
        selection_width?: number
        selection_height?: number
        launch_width?: number
        launch_height?: number
      }
    >
  }
  isOpen: boolean
  onRequestClose: () => void
  contextType: string
  contextId: number | string
  launchType: string
  contextModuleId?: string
  onExternalContentReady?: (data: any) => void
  onDeepLinkingResponse?: (data: any) => void
  resourceSelection?: boolean
}

export type ExternalToolModalLauncherSimplifiedProps = {
  appElement: Element
  isOpen: boolean
  onRequestClose: () => void
  iframeSrc: string
  title: string
  width?: number
  height?: number
}

export default class ExternalToolModalLauncher extends React.Component<
  ExternalToolModalLauncherProps | ExternalToolModalLauncherSimplifiedProps
> {
  removeExternalContentListener?: () => void
  removeCloseListener?: () => void
  iframe?: HTMLIFrameElement | null

  static defaultProps = {
    appElement: document.getElementById('application'),
  }

  componentDidMount() {
    this.removeExternalContentListener = handleExternalContentMessages({
      ready: this.onExternalToolCompleted,
      cancel: () => this.onExternalToolCompleted({}),
      onDeepLinkingResponse:
        'onDeepLinkingResponse' in this.props ? this.props.onDeepLinkingResponse : undefined,
    })

    const placement = 'tool' in this.props ? this.props.launchType : 'modal'
    this.removeCloseListener = onLtiClosePostMessage(placement, this.props.onRequestClose)
  }

  componentWillUnmount() {
    this.removeExternalContentListener?.()
    this.removeCloseListener?.()
  }

  onExternalToolCompleted = (data: any) => {
    if ('onExternalContentReady' in this.props) {
      this.props.onExternalContentReady?.(data)
    }
    this.props.onRequestClose()
  }

  getIframeSrc = () => {
    if ('iframeSrc' in this.props) {
      return this.props.iframeSrc
    }
    if (this.props.isOpen && 'tool' in this.props) {
      return [
        '/',
        this.props.contextType,
        's/',
        this.props.contextId,
        '/external_tools/',
        this.props.tool.definition_id,
        this.props.resourceSelection ? '/resource_selection' : '',
        '?display=borderless&launch_type=',
        this.props.launchType,
        this.props.contextModuleId && '&context_module_id=',
        this.props.contextModuleId,
      ].join('')
    }
  }

  getLaunchDimensions = () => {
    const dimensions = {
      width: 700,
      height: 700,
    }

    if ('width' in this.props && 'height' in this.props) {
      dimensions.width = this.props.width || dimensions.width
      dimensions.height = this.props.height || dimensions.height
    } else if (
      'tool' in this.props &&
      this.props.launchType &&
      this.props.tool.placements &&
      this.props.tool.placements[this.props.launchType]
    ) {
      const placement = this.props.tool.placements[this.props.launchType]
      dimensions.width = placement.launch_width || placement.selection_width || dimensions.width
      dimensions.height = placement.launch_height || placement.selection_height || dimensions.height
    }

    return dimensions
  }

  onAfterOpen = () => {
    if (this.iframe) {
      this.iframe.setAttribute('allow', iframeAllowances())
    }

    const observer = new MutationObserver(() => {
      const closeButton = document.querySelector(
        '[role="dialog"] button[data-cid="BaseButton"]',
      ) as HTMLButtonElement | null

      if (closeButton) {
        observer.disconnect()

        setTimeout(() => {
          requestAnimationFrame(() => {
            closeButton.setAttribute('tabindex', '-1')
            closeButton.focus()
          })
        }, 100)
      }
    })

    observer.observe(document.body, {
      childList: true,
      subtree: true,
    })
  }

  render() {
    const modalLaunchStyle = {
      ...this.getLaunchDimensions(),
      border: 'none',
    }

    return (
      <CanvasModal
        label={I18n.t('%{externalToolText}', {
          externalToolText: this.props.title || 'Launch External Tool',
        })}
        open={this.props.isOpen}
        onDismiss={this.props.onRequestClose}
        onOpen={this.onAfterOpen}
        title={this.props.title}
        appElement={this.props.appElement}
        shouldCloseOnDocumentClick={false}
        footer={null}
      >
        <ToolLaunchIframe
          src={this.getIframeSrc()}
          style={modalLaunchStyle}
          title={this.props.title}
          ref={e => {
            this.iframe = e
          }}
        />
      </CanvasModal>
    )
  }
}
