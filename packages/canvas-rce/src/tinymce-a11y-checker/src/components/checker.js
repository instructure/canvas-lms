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
import Select from "instructure-ui/lib/components/Select"
import ContextBox from "instructure-ui/lib/components/ContextBox"
import Grid from "instructure-ui/lib/components/Grid"
import GridRow from "instructure-ui/lib/components/Grid/GridRow"
import GridCol from "instructure-ui/lib/components/Grid/GridCol"
import Spinner from "instructure-ui/lib/components/Spinner"
import Typography from "instructure-ui/lib/components/Typography"
import IconCompleteSolid from "instructure-icons/lib/Solid/IconCompleteSolid"
import IconQuestionSolid from "instructure-icons/lib/Solid/IconQuestionSolid"
import ColorField from "./color-field"

import describe from "../utils/describe"
import * as dom from "../utils/dom"
import rules from "../rules"
import formatMessage from "format-message"

export default class Checker extends React.Component {
  constructor() {
    super()

    this.state = {
      open: false,
      checking: false,
      errors: [],
      formState: {},
      formStateValid: false,
      errorIndex: 0
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

  check(done) {
    this.setState(
      {
        open: true,
        checking: true,
        errors: [],
        errorIndex: 0
      },
      () => this._check(done)
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
              !rule.test(child)
            ) {
              errors.push({ node: child, rule })
            }
          }
        },
        () => {
          this.setState({ errors, checking: false }, () => {
            this.firstError()
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
      node = rule.update(node, this.state.formState)
      this.updateErrorNode(node)
      if (rule.test(node)) {
        this.removeError()
      }
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

  removeError() {
    const errors = this.state.errors.slice(0)
    errors.splice(this.state.errorIndex, 1)
    let errorIndex = this.state.errorIndex
    if (errorIndex >= errors.length) {
      errorIndex = 0
    }
    this.onLeaveError()
    if (errors.length === 0) {
      this.check()
    } else {
      this.setState({ errors, errorIndex }, this.selectCurrent)
    }
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
    const issueNumberMessage = formatMessage("Issue { num } of { total }", {
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
          closeButtonLabel={formatMessage("Close Accessibility Checker")}
          applicationElement={this.applicationElements}
        >
          <Container as="div" style={{ width: "20rem" }} padding="medium">
            <Heading level="h3" as="h2" margin="medium 0" color="brand">
              <IconCompleteSolid
                style={{
                  verticalAlign: "middle",
                  paddingBottom: "0.1em"
                }}
              />
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
                <Typography size="small">{issueNumberMessage}</Typography>
                <form onSubmit={this.fixIssue}>
                  <Container as="div" margin="x-small 0 medium">
                    <Grid
                      vAlign="middle"
                      hAlign="space-between"
                      colSpacing="none"
                    >
                      <GridRow>
                        <GridCol>
                          <Button onClick={this.prevError}>
                            {formatMessage("Prev")}
                          </Button>{" "}
                          <Button onClick={this.nextError} variant="primary">
                            {formatMessage("Next")}
                          </Button>
                        </GridCol>
                        <GridCol width="auto">
                          <Button
                            type="submit"
                            variant="success"
                            disabled={!this.state.formStateValid}
                          >
                            {formatMessage("Apply Fix")}
                          </Button>
                        </GridCol>
                      </GridRow>
                    </Grid>
                  </Container>
                  <Alert variant="warning">{this.errorMessage()}</Alert>
                  {rule.form().map(f => (
                    <Container as="div" key={f.dataKey} margin="medium 0 0">
                      {this.renderField(f)}
                    </Container>
                  ))}
                </form>
                <Container as="div" margin="large 0 0">
                  <Heading level="h4" as="h3" padding="0 0 x-small">
                    <IconQuestionSolid
                      style={{
                        verticalAlign: "middle",
                        paddingBottom: "0.1em"
                      }}
                    />
                    {" " + formatMessage("Why")}
                  </Heading>
                  <Typography size="small">
                    {rule.why() + " "}
                    <Link href={rule.link} target="_blank">
                      {formatMessage("Learn more")}
                    </Link>
                  </Typography>
                </Container>
              </Container>
            )}
            {this.state.errors.length === 0 &&
              !this.state.checking && (
                <Alert variant="success">
                  {formatMessage("No accessibility issues were detected.")}
                </Alert>
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
