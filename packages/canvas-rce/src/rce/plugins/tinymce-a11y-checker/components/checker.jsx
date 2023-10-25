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
/* eslint-disable jest/valid-describe */
// our own imported describe function confuses eslint

import React from 'react'

import {LiveAnnouncer, LiveMessage} from 'react-aria-live'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'
import {Grid, GridRow, GridCol} from '@instructure/ui-grid'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconQuestionLine} from '@instructure/ui-icons'
import {InstUISettingsProvider} from '@instructure/emotion'
import {Alert} from '@instructure/ui-alerts'
import ColorField from './ColorField'
import PlaceholderSVG from './placeholder-svg'

import describe from '../utils/describe'
import * as dom from '../utils/dom'
import checkNode from '../node-checker'
import formatMessage from '../../../../format-message'
import {clearIndicators} from '../utils/indicate'
import {getTrayHeight} from '../../shared/trayUtils'
import {instuiPopupMountNode} from '../../../../util/fullscreenHelpers'

// safari still doesn't support the standard api
const FS_CHANGEEVENT = document.exitFullscreen ? 'fullscreenchange' : 'webkitfullscreenchange'

const noop = () => {}

export default class Checker extends React.Component {
  state = {
    open: false,
    checking: false,
    errors: [],
    formState: {},
    formStateValid: false,
    errorIndex: 0,
    config: {},
    showWhyPopover: false,
  }

  static defaultProps = {
    additionalRules: [],
    onFixError: noop,
  }

  componentDidMount() {
    this.props.editor.on('Remove', _editor => {
      this.setState({open: false}, () => {
        this.props.onClose()
      })
    })
  }

  componentDidUpdate(_prevProps, prevState) {
    if (prevState.open !== this.state.open) {
      if (this.state.open) {
        window.addEventListener(FS_CHANGEEVENT, this.onFullscreenChange)
      } else {
        window.removeEventListener(FS_CHANGEEVENT, this.onFullscreenChange)
      }
    }
  }

  onFullscreenChange = _event => {
    this.selectCurrent()
  }

  setConfig(config) {
    this.setState({config})
  }

  check(done) {
    if (typeof done !== 'function') done = noop

    this.setState(
      {
        open: true,
        checking: true,
        errors: [],
        errorIndex: 0,
      },
      () => {
        if (typeof this.state.config.beforeCheck === 'function') {
          this.state.config.beforeCheck(this.props.editor, () => {
            this._check(() => {
              if (typeof this.state.config.afterCheck === 'function') {
                this.state.config.afterCheck(this.props.editor, done)
              } else {
                done()
              }
            })
          })
        } else if (typeof this.state.config.afterCheck === 'function') {
          this._check(() => {
            this.state.config.afterCheck(this.props.editor, done)
          })
        } else {
          this._check(done)
        }
      }
    )
  }

  _check(done) {
    const node = this.props.getBody()
    const checkDone = errors => {
      this.setState({errorIndex: 0, errors, checking: false}, () => {
        this.selectCurrent()
        done()
      })
    }
    checkNode(node, checkDone, this.state.config, this.props.additionalRules)
  }

  firstError() {
    if (this.state.errors.length > 0) {
      this.setErrorIndex(0)
    }
  }

  nextError() {
    const next = (this.state.errorIndex + 1) % this.state.errors.length
    this.setErrorIndex(next)
  }

  prevError() {
    const len = this.state.errors.length
    const prev = (len + this.state.errorIndex - 1) % len
    this.setErrorIndex(prev)
  }

  setErrorIndex(errorIndex) {
    this.onLeaveError()
    if (errorIndex >= this.state.errors.length) {
      errorIndex = 0
    }
    this.setState({errorIndex}, () => this.selectCurrent())
  }

  selectCurrent() {
    clearIndicators(this.props.editor.dom.doc)
    const errorNode = this.errorNode()
    if (errorNode) {
      this.getFormState()
      dom.select(errorNode)
    } else {
      this.firstError()
    }
  }

  error() {
    return this.state.errors[this.state.errorIndex]
  }

  errorNode() {
    const error = this.error()
    return error && error.node
  }

  errorRootNode() {
    const rule = this.errorRule()
    const rootNode = rule && rule.rootNode && rule.rootNode(this.errorNode())
    return rootNode || this.errorNode()
  }

  updateErrorNode(elem) {
    const error = this.error()
    if (error) {
      error.node = elem
    }
  }

  errorRule() {
    const error = this.error()
    return error && error.rule
  }

  errorMessage() {
    const rule = this.errorRule()
    return rule && rule.message()
  }

  getFormState() {
    const rule = this.errorRule()
    const node = this.errorNode()
    if (rule && node) {
      this.setState({formState: rule.data(node), formStateValid: false})
    }
  }

  updateFormState = ({target}) => {
    this.setState(prevState => {
      const formState = {...prevState.formState}
      if (target.type === 'checkbox') {
        formState[target.name] = target.checked
      } else {
        formState[target.name] = target.value
      }
      return {
        formState,
        formStateValid: this.formStateValid(formState),
      }
    })
  }

  formStateValid(formState) {
    formState = formState || this.state.formState
    let node = this.tempNode(true)
    const rule = this.errorRule()
    if (!node || !rule) {
      return false
    }
    node = rule.update(node, formState)
    if (this._tempNode === this._tempTestNode) {
      this._tempNode = node
    }
    this._tempTestNode = node
    return rule.test(node)
  }

  fixIssue() {
    const rule = this.errorRule()
    const node = this.errorNode()
    if (rule && node) {
      this.removeTempNode()
      rule.update(node, this.state.formState)
      this.updateErrorNode(node)
      if (this._closeButtonRef) {
        this._closeButtonRef.focus()
      }
      const errorIndex = this.state.errorIndex
      this.check(() => {
        this.setErrorIndex(errorIndex)
        this.props.onFixError(this.state.errors)
      })
    }
  }

  newTempRootNode(rootNode) {
    const newTempRootNode = rootNode.cloneNode(true)
    const path = dom.pathForNode(rootNode, this.errorNode())
    this._tempTestNode = dom.nodeByPath(newTempRootNode, path)
    return newTempRootNode
  }

  tempNode(refresh = false) {
    if (!this._tempNode || refresh) {
      const rootNode = this.errorRootNode()
      if (rootNode) {
        const newTempRtNode = this.newTempRootNode(rootNode)
        if (refresh && this._tempNode) {
          const parent = this._tempNode.parentNode
          parent.insertBefore(newTempRtNode, this._tempNode)
          parent.removeChild(this._tempNode)
        } else {
          const parent = rootNode.parentNode
          parent.insertBefore(newTempRtNode, rootNode)
          parent.removeChild(rootNode)
        }
        this._tempNode = newTempRtNode
      }
    }
    return this._tempTestNode
  }

  removeTempNode() {
    const node = this.errorRootNode()
    if (this._tempNode && node) {
      const parent = this._tempNode.parentNode
      parent.insertBefore(node, this._tempNode)
      parent.removeChild(this._tempNode)
      this._tempNode = null
      this._tempTestNode = null
    }
  }

  onLeaveError() {
    this.removeTempNode()
  }

  handleClose() {
    this.onLeaveError()
    clearIndicators(this.props.editor.dom.doc)
    this.setState({open: false}, () => {
      this.props.onClose()
    })
  }

  render() {
    const rule = this.errorRule()
    const issueNumberMessage = formatMessage('Issue { num }/{ total }', {
      num: this.state.errorIndex + 1,
      total: this.state.errors.length,
    })

    return (
      <LiveAnnouncer>
        <Tray
          data-mce-component={true}
          label={formatMessage('Accessibility Checker')}
          mountNode={this.props.mountNode}
          open={this.state.open}
          onDismiss={() => this.handleClose()}
          placement="end"
          contentRef={e => (this.trayElement = e)}
          size="regular"
          themeOverride={{regularWidth: '22em'}}
        >
          <Flex direction="column" height={getTrayHeight()}>
            <Flex.Item as="header" padding="medium medium small">
              <Flex direction="row">
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <Heading as="h2">{formatMessage('Accessibility Checker')}</Heading>
                </Flex.Item>
                <Flex.Item>
                  <CloseButton
                    screenReaderLabel={formatMessage('Close Accessibility Checker')}
                    placement="end"
                    onClick={() => this.handleClose()}
                    elementRef={ref => (this._closeButtonRef = ref)}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>
            <Flex.Item as="div" padding="0 large large">
              {this.state.errors.length > 0 && (
                <View as="div">
                  <LiveMessage
                    aria-live="polite"
                    message={`
                  ${issueNumberMessage}
                  ${describe(this.errorNode())}
                  ${this.errorMessage()}
                `}
                  />
                  <View as="div" margin="large 0 medium 0">
                    <Grid vAlign="middle" hAlign="space-between" colSpacing="none">
                      <GridRow>
                        <GridCol>
                          <Text weight="bold">{issueNumberMessage}</Text>
                        </GridCol>
                        <GridCol width="auto">
                          <Popover
                            on="click"
                            isShowingContent={this.state.showWhyPopover}
                            shouldContainFocus={true}
                            shouldReturnFocus={true}
                            renderTrigger={() => (
                              <IconButton
                                screenReaderLabel={formatMessage('Why')}
                                renderIcon={IconQuestionLine}
                                onClick={() => this.setState({showWhyPopover: true})}
                                withBackground={false}
                                withBorder={false}
                              >
                                <IconQuestionLine />
                              </IconButton>
                            )}
                          >
                            <View padding="medium" display="block" width="16rem">
                              <CloseButton
                                placement="end"
                                offset="x-small"
                                onClick={() => this.setState({showWhyPopover: false})}
                                screenReaderLabel={formatMessage('Close')}
                              />
                              <Text>
                                <p>{rule.why()}</p>
                                <p>
                                  {rule.link && rule.link.length && (
                                    <InstUISettingsProvider
                                      themeOverride={{
                                        componentOverrides: {
                                          [Link.componentId]: {
                                            textDecoration: 'underline',
                                          },
                                        },
                                      }}
                                    >
                                      <Link href={rule.link} target="_blank">
                                        {rule.linkText()}
                                      </Link>
                                    </InstUISettingsProvider>
                                  )}
                                </p>
                              </Text>
                            </View>
                          </Popover>
                        </GridCol>
                      </GridRow>
                    </Grid>
                  </View>
                  <form
                    onSubmit={event => {
                      event.preventDefault()
                      this.fixIssue()
                    }}
                  >
                    <Text as="div">{this.errorMessage()}</Text>
                    {rule.form().map(f => (
                      <View as="div" key={f.dataKey} margin="medium 0 0">
                        {this.renderField(f)}
                      </View>
                    ))}
                    <View as="div" margin="medium 0">
                      <Grid vAlign="middle" hAlign="space-between" colSpacing="none">
                        <GridRow>
                          <GridCol>
                            <Button
                              onClick={() => this.prevError()}
                              margin="0 small 0 0"
                              aria-label="Previous"
                              disabled={this.state.errors.length < 2}
                            >
                              {formatMessage('Prev')}
                            </Button>
                            <Button
                              onClick={() => this.nextError()}
                              disabled={this.state.errors.length < 2}
                            >
                              {formatMessage('Next')}
                            </Button>
                          </GridCol>
                          <GridCol width="auto">
                            <Button
                              type="submit"
                              color="primary"
                              disabled={!this.state.formStateValid}
                            >
                              {formatMessage('Apply')}
                            </Button>
                          </GridCol>
                        </GridRow>
                      </Grid>
                    </View>
                  </form>
                </View>
              )}
              {this.state.errors.length === 0 && !this.state.checking && (
                <View>
                  <Text>
                    <p>{formatMessage('No accessibility issues were detected.')}</p>
                  </Text>
                  <PlaceholderSVG />
                </View>
              )}
              {this.state.checking && (
                <div>
                  <LiveMessage
                    message={formatMessage('Checking for accessibility issues')}
                    aria-live="polite"
                  />
                  <Spinner
                    renderTitle={formatMessage('Checking for accessibility issues')}
                    margin="medium auto"
                  />
                </div>
              )}
            </Flex.Item>
          </Flex>
        </Tray>
      </LiveAnnouncer>
    )
  }

  renderField(f) {
    const disabled = !!f.disabledIf && f.disabledIf(this.state.formState)
    switch (true) {
      case !!f.options:
        return (
          <SimpleSelect
            mountNode={instuiPopupMountNode}
            disabled={disabled}
            onChange={(e, option) => {
              this.updateFormState({
                target: {
                  name: f.dataKey,
                  value: option.value,
                },
              })
            }}
            value={this.state.formState[f.dataKey]}
            renderLabel={() => f.label}
          >
            {f.options.map(o => (
              <SimpleSelect.Option key={o[0]} id={o[0]} value={o[0]}>
                {o[1]}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        )
      case f.checkbox:
        return (
          <Checkbox
            label={f.label}
            name={f.dataKey}
            checked={this.state.formState[f.dataKey]}
            onChange={this.updateFormState}
            disabled={disabled}
          />
        )
      case f.color:
        return (
          <ColorField
            label={f.label}
            name={f.dataKey}
            value={this.state.formState[f.dataKey] || ''}
            onChange={this.updateFormState}
            key={this.state.formState.id}
          />
        )
      case f.textarea:
        return (
          <TextArea
            label={f.label}
            name={f.dataKey}
            value={this.state.formState[f.dataKey]}
            onChange={this.updateFormState}
            disabled={disabled}
          />
        )
      case f.alert:
        return (
          this.state.formState.action === 'elem-only' && (
            <Alert name={f.dataKey} variant={f.variant}>
              {f.message}
            </Alert>
          )
        )
      default:
        return (
          <TextInput
            renderLabel={f.label}
            name={f.dataKey}
            value={this.state.formState[f.dataKey] || ''}
            onChange={this.updateFormState}
            disabled={disabled}
          />
        )
    }
  }
}
