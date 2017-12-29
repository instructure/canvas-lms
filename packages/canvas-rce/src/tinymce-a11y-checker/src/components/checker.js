import React from "react"

import { LiveAnnouncer, LiveMessage } from "react-aria-live"
import Tray from "instructure-ui/lib/components/Tray"
import Container from "instructure-ui/lib/components/Container"
import Heading from "instructure-ui/lib/components/Heading"
import Button from "instructure-ui/lib/components/Button"
import Link from "instructure-ui/lib/components/Link"
import Alert from "instructure-ui/lib/components/Alert"
import Checkbox from "instructure-ui/lib/components/Checkbox"
import TextInput from "instructure-ui/lib/components/TextInput"
import TextArea from "instructure-ui/lib/components/TextArea"
import Select from "instructure-ui/lib/components/Select"
import ContextBox from "instructure-ui/lib/components/ContextBox"
import Grid from "instructure-ui/lib/components/Grid"
import GridRow from "instructure-ui/lib/components/Grid/GridRow"
import GridCol from "instructure-ui/lib/components/Grid/GridCol"
import Spinner from "instructure-ui/lib/components/Spinner"
import Popover, {
  PopoverTrigger,
  PopoverContent
} from "instructure-ui/lib/components/Popover"
import Typography from "instructure-ui/lib/components/Typography"
import IconQuestionLine from "instructure-icons/lib/Line/IconQuestionLine"
import ColorField from "./color-field"
import PlaceholderSVG from "./placeholder-svg"

import describe from "../utils/describe"
import * as dom from "../utils/dom"
import rules from "../rules"
import formatMessage from "../format-message"

const noop = () => {}

export default class Checker extends React.Component {
  constructor() {
    super()

    this.state = {
      open: false,
      checking: false,
      errors: [],
      formState: {},
      formStateValid: false,
      errorIndex: 0,
      config: {}
    }

    this.firstError = this.firstError.bind(this)
    this.nextError = this.nextError.bind(this)
    this.prevError = this.prevError.bind(this)
    this.selectCurrent = this.selectCurrent.bind(this)
    this.updateFormState = this.updateFormState.bind(this)
    this.fixIssue = this.fixIssue.bind(this)
    this.handleClose = this.handleClose.bind(this)
  }

  static get displayName() {
    return "Checker"
  }

  componentWillUnmount() {
    clearTimeout(this._closeTimout)
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
          for (let rule of rules) {
            if (
              !child.hasAttribute("data-ignore-a11y-check") &&
              !rule.test(child, this.state.config)
            ) {
              errors.push({ node: child, rule })
            }
          }
        },
        () => {
          this.setState({ errorIndex: 0, errors, checking: false }, () => {
            this.selectCurrent()
            if (typeof done === "function") {
              done()
            }
          })
          if (errors.length === 0) {
            this._closeTimout = setTimeout(this.handleClose, 3000)
          }
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
    this.setState({ errorIndex }, this.selectCurrent)
  }

  selectCurrent() {
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
      this.setState({ formState: rule.data(node), formStateValid: false })
    }
  }

  updateFormState({ target }) {
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

  fixIssue(ev) {
    ev.preventDefault()
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
    this.setState({ open: false })
  }

  applicationElements() {
    const _filter = Array.prototype.filter
    return _filter.call(
      document.body.childNodes,
      node =>
        node.nodeType == 1 &&
        node.className !== "tinymce-a11y-checker-container"
    )
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
          isDismissable
          shouldContainFocus
          open={this.state.open}
          onDismiss={this.handleClose}
          placement="end"
          mountNode={() =>
            document.getElementsByClassName(
              "tinymce-a11y-checker-container"
            )[0]}
          closeButtonLabel={formatMessage("Close Accessibility Checker")}
          applicationElement={this.applicationElements}
        >
          <Container as="div" style={{ width: "20rem" }} padding="medium">
            <Heading level="h3" as="h2" margin="medium 0">
              {" " + formatMessage("Accessibility Checker")}
            </Heading>
            {this.state.errors.length > 0 && (
              <Container as="div">
                <LiveMessage
                  aria-live="polite"
                  message={`
                  ${issueNumberMessage}
                  ${describe(this.errorNode())}
                  ${this.errorMessage()}
                `}
                />
                <Container as="div" margin="large 0 medium 0">
                  <Grid
                    vAlign="middle"
                    hAlign="space-between"
                    colSpacing="none"
                  >
                    <GridRow>
                      <GridCol>
                        <Typography weight="bold">
                          {issueNumberMessage}
                        </Typography>
                      </GridCol>
                      <GridCol width="auto">
                        <Popover
                          on="click"
                          shouldContainFocus
                          shouldReturnFocus
                          closeButtonLabel="Close"
                          applicationElement={() =>
                            document.getElementsByClassName(
                              "tinymce-a11y-checker-container"
                            )[0]}
                        >
                          <PopoverTrigger>
                            <Button variant="icon">
                              <IconQuestionLine title={formatMessage("Why")} />
                            </Button>
                          </PopoverTrigger>
                          <PopoverContent>
                            <Container
                              padding="medium"
                              display="block"
                              style={{ width: "16rem" }}
                            >
                              <Typography>
                                <p>
                                  {rule.why() + " "}
                                  {rule.link &&
                                    rule.link.length && (
                                      <Link href={rule.link} target="_blank">
                                        {formatMessage("Learn more")}
                                      </Link>
                                    )}
                                </p>
                              </Typography>
                            </Container>
                          </PopoverContent>
                        </Popover>
                      </GridCol>
                    </GridRow>
                  </Grid>
                </Container>
                <form onSubmit={this.fixIssue}>
                  <Typography as="div">{this.errorMessage()}</Typography>
                  {rule.form().map(f => (
                    <Container as="div" key={f.dataKey} margin="medium 0 0">
                      {this.renderField(f)}
                    </Container>
                  ))}
                  <Container as="div" margin="medium 0">
                    <Grid
                      vAlign="middle"
                      hAlign="space-between"
                      colSpacing="none"
                    >
                      <GridRow>
                        <GridCol>
                          <Button onClick={this.prevError} margin="0 small 0 0">
                            {formatMessage("Prev")}
                          </Button>
                          <Button onClick={this.nextError}>
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
                  </Container>
                </form>
              </Container>
            )}
            {this.state.errors.length === 0 &&
              !this.state.checking && (
                <Container>
                  <Typography>
                    <p>
                      {formatMessage("No accessibility issues were detected.")}
                    </p>
                  </Typography>
                  <PlaceholderSVG />
                </Container>
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
          </Container>
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
