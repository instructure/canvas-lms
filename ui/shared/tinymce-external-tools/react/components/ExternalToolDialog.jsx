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

import {replaceTags} from '../../helpers/tags'
import React from 'react'
import PropTypes from 'prop-types'
import ExternalToolDialogModal from './ExternalToolDialog/Modal'
import ExternalToolDialogTray from './ExternalToolDialog/Tray'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import {send} from '@canvas/rce/RceCommandShim'
import TinyMCEContentItem from '../../TinyMCEContentItem'
import processEditorContentItems from '@canvas/deep-linking/processors/processEditorContentItems'
import {Flex} from '@instructure/ui-flex'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'
import {instuiPopupMountNode} from '@instructure/canvas-rce'

const I18n = useI18nScope('ExternalToolDialog')

const EMPTY_BUTTON = {
  height: 300,
  width: 400,
  name: ' ',
}

const EMPTY_FORM = {
  url: '',
  selection: '',
  contents: '',
}

export default class ExternalToolDialog extends React.Component {
  static propTypes = {
    win: PropTypes.shape({
      addEventListener: PropTypes.func.isRequired,
      removeEventListener: PropTypes.func.isRequired,
      confirm: PropTypes.func.isRequired,
      dispatchEvent: PropTypes.func.isRequired,
      innerHeight: PropTypes.number.isRequired,
      $: PropTypes.func.isRequired,
    }).isRequired,
    editor: PropTypes.shape({
      id: PropTypes.string.isRequired,
      selection: PropTypes.shape({
        getContent: PropTypes.func.isRequired,
      }),
      getContent: PropTypes.func.isRequired,
      focus: PropTypes.func.isRequired,
    }).isRequired,
    contextAssetString: PropTypes.string.isRequired,
    iframeAllowances: PropTypes.string.isRequired,
    resourceSelectionUrl: PropTypes.string,
    deepLinkingOrigin: PropTypes.string,
  }

  static defaultProps = {
    resourceSelectionUrl: null,
    deepLinkingOrigin: '',
  }

  state = {
    open: false,
    button: EMPTY_BUTTON,
    infoAlert: null,
    form: EMPTY_FORM,
    iframeLoaded: false,
  }

  open(button) {
    const {win, editor, contextAssetString, resourceSelectionUrl} = this.props
    let url = replaceTags(resourceSelectionUrl, 'id', button.id)
    const selection = editor.selection.getContent() || ''
    const contents = editor.getContent() || ''
    if (url == null) {
      // if we don't have a url on the page, build one using the current context.
      // url should look like: /courses/2/external_tools/15/resource_selection?editor=1
      const asset = contextAssetString.split('_')
      url = `/${asset[0]}s/${asset[1]}/external_tools/${button.id}/resource_selection`
    }
    this.setState({open: true, button, form: {url, selection, contents}})
    win.addEventListener('beforeunload', this.handleBeforeUnload)
    win.addEventListener('message', this.handleDeepLinking)
    win.$(win).bind('externalContentReady', this.handleExternalContentReady)
  }

  close() {
    const {win} = this.props
    win.removeEventListener('beforeunload', this.handleBeforeUnload)
    win.removeEventListener('message', this.handleDeepLinking)
    win.$(win).unbind('externalContentReady')
    this.setState({open: false, form: EMPTY_FORM})
  }

  handleBeforeUnload = ev => (ev.returnValue = I18n.t('Changes you made may not be saved.'))

  handleExternalContentReady = (ev, data) => {
    // a2DataReady listener will insert the data to the editor,
    // So only close the modal is needed, only if assignments_2_student flag is enabled,
    // is readable by current user and it is a student assignment view.
    if (ENV.a2_student_view) {
      this.close()
      return
    }

    const {editor, win} = this.props
    const contentItems = data.contentItems
    if (contentItems.length === 1 && contentItems[0]['@type'] === 'lti_replace') {
      const code = contentItems[0].text
      send(win.$(`#${editor.id}`), 'set_code', code)
    } else {
      for (let i = 0, len = contentItems.length; i < len; ++i) {
        const contentData = contentItems[i]
        contentData.class = 'lti-embed'
        const code = TinyMCEContentItem.fromJSON(contentData).codePayload
        send(win.$(`#${editor.id}`), 'insert_code', code)
      }
    }
    this.close()
  }

  handleDeepLinking = ev => {
    const {editor, deepLinkingOrigin} = this.props
    // Only accept messages from the same origin
    if (
      ev.origin === deepLinkingOrigin &&
      ev.data &&
      ev.data.subject === 'LtiDeepLinkingResponse'
    ) {
      processEditorContentItems(ev, editor, this)
    }
  }

  handleClose = () => {
    const {win} = this.props
    const msg = I18n.t('Are you sure you want to cancel? Changes you made may not be saved.')
    if (win.confirm(msg)) {
      this.close()
    }
  }

  handleOpen = () => {
    if (this.state.open) this.formRef.submit()
  }

  handleRemove = () => {
    this.setState({button: EMPTY_BUTTON})
    this.props.editor.focus()
    // force tinyMCE to redraw sticky toolbar otherwise it never goes away
    this.props.win.dispatchEvent(new Event('resize'))
  }

  handleInfoAlertFocus = ev => this.setState({infoAlert: ev.target})

  handleInfoAlertBlur = () => this.setState({infoAlert: null})

  render() {
    const {open, button, form, infoAlert, iframeLoaded} = this.state
    const {iframeAllowances, win} = this.props
    const label = I18n.t('embed_from_external_tool', 'Embed content from External Tool')
    const frameHeight = Math.max(Math.min(win.innerHeight - 100, 550), 100)
    const Overlay = button.use_tray ? ExternalToolDialogTray : ExternalToolDialogModal
    return (
      <>
        <form
          ref={ref => (this.formRef = ref)}
          method="POST"
          action={form.url}
          target="external_tool_launch"
          style={{margin: 0}}
        >
          <input type="hidden" name="editor" value="1" />
          <input type="hidden" name="selection" value={form.selection} />
          <input type="hidden" name="editor_contents" value={form.contents} />
        </form>
        <Overlay
          open={open}
          mountNode={instuiPopupMountNode}
          label={label}
          onOpen={this.handleOpen}
          onClose={this.handleRemove}
          onCloseButton={this.handleClose}
          name={button.name}
        >
          <div
            ref={ref => (this.beforeInfoAlertRef = ref)}
            tabIndex="0" // eslint-disable-line jsx-a11y/no-noninteractive-tabindex
            onFocus={this.handleInfoAlertFocus}
            onBlur={this.handleInfoAlertBlur}
            className={
              infoAlert && infoAlert === this.beforeInfoAlertRef ? '' : 'screenreader-only'
            }
          >
            <Alert margin="small">{I18n.t('The following content is partner provided')}</Alert>
          </div>
          {!iframeLoaded && (
            <Flex alignItems="center" justifyItems="center">
              <Flex.Item>
                <Spinner
                  renderTitle={I18n.t('Loading External Tool')}
                  size="large"
                  margin="0 0 0 medium"
                />
              </Flex.Item>
            </Flex>
          )}

          <ToolLaunchIframe
            title={label}
            ref={ref => (this.iframeRef = ref)}
            name="external_tool_launch"
            src=""
            id="external_tool_button_frame"
            style={{
              width: button.use_tray ? '100%' : button.width || 800,
              height: button.use_tray ? '100%' : button.height || frameHeight,
              border: '0',
              display: 'block',
              visibility: iframeLoaded ? 'visible' : 'hidden',
            }}
            allow={iframeAllowances}
            borderstyle="0"
            onLoad={() => this.setState({iframeLoaded: true})}
          />
          <div
            ref={ref => (this.afterInfoAlertRef = ref)}
            tabIndex="0" // eslint-disable-line jsx-a11y/no-noninteractive-tabindex
            onFocus={this.handleInfoAlertFocus}
            onBlur={this.handleInfoAlertBlur}
            className={infoAlert && infoAlert === this.afterInfoAlertRef ? '' : 'screenreader-only'}
          >
            <Alert margin="small">{I18n.t('The preceding content is partner provided')}</Alert>
          </div>
        </Overlay>
      </>
    )
  }
}
