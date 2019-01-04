import React from "react"

import preventDefault from "prevent-default"
import { LiveAnnouncer, LiveMessage } from "react-aria-live"
import ScreenReaderContent from "@instructure/ui-a11y/lib/components/ScreenReaderContent"
import CloseButton from "@instructure/ui-buttons/lib/components/CloseButton"
import Tray from "@instructure/ui-overlays/lib/components/Tray"
import View from "@instructure/ui-layout/lib/components/View"
import Heading from "@instructure/ui-elements/lib/components/Heading"
import Button from "@instructure/ui-buttons/lib/components/Button"
import Link from "@instructure/ui-elements/lib/components/Link"
import Checkbox from "@instructure/ui-forms/lib/components/Checkbox"
import TextInput from "@instructure/ui-forms/lib/components/TextInput"
import TextArea from "@instructure/ui-forms/lib/components/TextArea"
import Select from "@instructure/ui-core/lib/components/Select"
import Grid from "@instructure/ui-layout/lib/components/Grid"
import GridRow from "@instructure/ui-layout/lib/components/Grid/GridRow"
import GridCol from "@instructure/ui-layout/lib/components/Grid/GridCol"
import Spinner from "@instructure/ui-elements/lib/components/Spinner"
import Popover, {
  PopoverTrigger,
  PopoverContent
} from "@instructure/ui-overlays/lib/components/Popover"
import Text from "@instructure/ui-elements/lib/components/Text"
import IconQuestionLine from "@instructure/ui-icons/lib/Line/IconQuestion"
import ApplyTheme from "@instructure/ui-themeable/lib/components/ApplyTheme"
import ColorField from "./color-field"
import PlaceholderSVG from "./placeholder-svg"

import describe from "../utils/describe"
import * as dom from "../utils/dom"
import rules from "../rules"
import formatMessage from "../format-message"
import { clearIndicators } from "../utils/indicate"

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
    showWhyPopover: false
  }

  static defaultProps = {
    additionalRules: []
  }

  static get displayName() {
    return "Checker"
  }

  setConfig(config) {
    this.setState({ config })
  }

  check(done = noop) {
    this.setState(
      {
        open: true,
        checking: true,
        errors: [],
        errorIndex: 0
      },
      () => {
        if (typeof this.state.config.beforeCheck === "function") {
          this.state.config.beforeCheck(this.props.editor, () => {
            this._check(() => {
              if (typeof this.state.config.afterCheck === "function") {
                this.state.config.afterCheck(this.props.editor, done)
              } else {
                done()
              }
            })
          })
        } else if (typeof this.state.config.afterCheck === "function") {
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
    const errors = []
    if (node) {
      dom.walk(
        node,
        child => {
          const composedRules = rules.concat(this.props.additionalRules)
          for (let rule of composedRules) {
            if (child.hasAttribute("data-ignore-a11y-check")) {
              continue
            }
            const promise = Promise.resolve(
              rule.test(child, this.state.config)
            ).then(result => {
              if (!result) {
                errors.push({ node: child, rule })
              }
            })
          }
        },
        () => {
          this.setState({ errorIndex: 0, errors, checking: false }, () => {
            this.selectCurrent()
            if (typeof done === "function") {
              done()
            }
          })
        }
      )
    }
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
    this.setState({ errorIndex }, () => this.selectCurrent())
  }

  selectCurrent() {
    clearIndicators()
    const errorNode = this.errorNode()
    if (errorNode) {
      this.getFormState()
      dom.select(this.props.editor, errorNode)
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
      this.setState({ formState: rule.data(node), formStateValid: false })
    }
  }

  updateFormState = ({ target }) => {
    const formState = Object.assign({}, this.state.formState)
    if (target.type === "checkbox") {
      formState[target.name] = target.checked
    } else {
      formState[target.name] = target.value
    }
    this.setState({
      formState,
      formStateValid: this.formStateValid(formState)
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
    let node = this.errorNode()
    if (rule && node) {
      this.removeTempNode()
      rule.update(node, this.state.formState)
      this.updateErrorNode(node)
      const errorIndex = this.state.errorIndex
      this.check(() => this.setErrorIndex(errorIndex))
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
    clearIndicators()
    this.setState({ open: false })
  }

  render() {
    const rule = this.errorRule()
    const issueNumberMessage = formatMessage("Issue { num }/{ total }", {
      num: this.state.errorIndex + 1,
      total: this.state.errors.length
    })

    return (
      <LiveAnnouncer>
        <Tray
          label={formatMessage("Accessibility Checker")}
          open={this.state.open}
          onDismiss={() => this.handleClose()}
          placement="end"
          contentRef={e => (this.trayElement = e)}
        >
          <CloseButton
            placement="start"
            offset="x-small"
            onClick={() => this.handleClose()}
          >
            {formatMessage("Close Accessibility Checker")}
          </CloseButton>
          <View as="div" padding="x-large large">
            <Heading level="h3" as="h2" margin="medium 0">
              {" " + formatMessage("Accessibility Checker")}
            </Heading>
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
                  <Grid
                    vAlign="middle"
                    hAlign="space-between"
                    colSpacing="none"
                  >
                    <GridRow>
                      <GridCol>
                        <Text weight="bold">{issueNumberMessage}</Text>
                      </GridCol>
                      <GridCol width="auto">
                        <Popover
                          on="click"
                          show={this.state.showWhyPopover}
                          shouldContainFocus
                          shouldReturnFocus
                        >
                          <PopoverTrigger>
                            <Button
                              variant="icon"
                              icon={IconQuestionLine}
                              onDismiss={() => {
                                this.setState({ showWhyPopover: false })
                              }}
                              onClick={() =>
                                this.setState({ showWhyPopover: true })
                              }
                            >
                              <ScreenReaderContent>
                                {formatMessage("Why")}
                              </ScreenReaderContent>
                            </Button>
                          </PopoverTrigger>
                          <PopoverContent>
                            <View
                              padding="medium"
                              display="block"
                              width="16rem"
                            >
                              <CloseButton
                                placement="end"
                                offset="x-small"
                                variant="icon"
                                onClick={() =>
                                  this.setState({ showWhyPopover: false })
                                }
                              >
                                {formatMessage("Close")}
                              </CloseButton>
                              <Text>
                                <p>{rule.why()}</p>
                                <p>
                                  {rule.link && rule.link.length && (
                                    <ApplyTheme
                                      theme={{
                                        [Link.theme]: {
                                          textDecoration: "underline"
                                        }
                                      }}
                                    >
                                      <Link href={rule.link} target="_blank">
                                        {rule.linkText()}
                                      </Link>
                                    </ApplyTheme>
                                  )}
                                </p>
                              </Text>
                            </View>
                          </PopoverContent>
                        </Popover>
                      </GridCol>
                    </GridRow>
                  </Grid>
                </View>
                <form onSubmit={preventDefault(() => this.fixIssue())}>
                  <Text as="div">{this.errorMessage()}</Text>
                  {rule.form().map(f => (
                    <View as="div" key={f.dataKey} margin="medium 0 0">
                      {this.renderField(f)}
                    </View>
                  ))}
                  <View as="div" margin="medium 0">
                    <Grid
                      vAlign="middle"
                      hAlign="space-between"
                      colSpacing="none"
                    >
                      <GridRow>
                        <GridCol>
                          <Button
                            onClick={() => this.prevError()}
                            margin="0 small 0 0"
                            aria-label="Previous"
                          >
                            {formatMessage("Prev")}
                          </Button>
                          <Button onClick={() => this.nextError()}>
                            {formatMessage("Next")}
                          </Button>
                        </GridCol>
                        <GridCol width="auto">
                          <Button
                            type="submit"
                            variant="primary"
                            disabled={!this.state.formStateValid}
                          >
                            {formatMessage("Apply")}
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
                  <p>
                    {formatMessage("No accessibility issues were detected.")}
                  </p>
                </Text>
                <PlaceholderSVG />
              </View>
            )}
            {this.state.checking && (
              <div>
                <LiveMessage
                  message={formatMessage("Checking for accessibility issues")}
                  aria-live="polite"
                />
                <Spinner
                  title={formatMessage("Checking for accessibility issues")}
                  margin="medium auto"
                />
              </div>
            )}
          </View>
        </Tray>
      </LiveAnnouncer>
    )
  }

  renderField(f) {
    const disabled = !!f.disabledIf && f.disabledIf(this.state.formState)
    switch (true) {
      case !!f.options:
        return (
          <Select
            label={f.label}
            name={f.dataKey}
            value={this.state.formState[f.dataKey]}
            onChange={this.updateFormState}
            disabled={disabled}
          >
            {f.options.map(o => (
              <option key={o[0]} value={o[0]}>
                {o[1]}
              </option>
            ))}
          </Select>
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
            value={this.state.formState[f.dataKey]}
            onChange={this.updateFormState}
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
      default:
        return (
          <TextInput
            label={f.label}
            name={f.dataKey}
            value={this.state.formState[f.dataKey]}
            onChange={this.updateFormState}
            disabled={disabled}
          />
        )
    }
  }
}
