const React = require('react')

const Tray = require('instructure-ui/lib/components/Tray').default
const Container = require('instructure-ui/lib/components/Container').default
const Heading = require('instructure-ui/lib/components/Heading').default
const Button = require('instructure-ui/lib/components/Button').default
const Link = require('instructure-ui/lib/components/Link').default
const Alert = require('instructure-ui/lib/components/Alert').default
const TextInput = require('instructure-ui/lib/components/TextInput').default
const Select = require('instructure-ui/lib/components/Select').default
const ContextBox = require('instructure-ui/lib/components/ContextBox').default
const Grid = require('instructure-ui/lib/components/Grid').default
const GridRow = require('instructure-ui/lib/components/Grid/GridRow').default
const GridCol = require('instructure-ui/lib/components/Grid/GridCol').default
const Spinner = require('instructure-ui/lib/components/Spinner').default
const ColorField = require('./color-field')

const Typography = require('instructure-ui/lib/components/Typography').default
const IconCompleteSolid = require('instructure-icons/lib/Solid/IconCompleteSolid').default
const IconQuestionSolid = require('instructure-icons/lib/Solid/IconQuestionSolid').default

const dom = require('../utils/dom')
const rules = require('../rules')
const formatMessage = require('../format-message')

class Checker extends React.Component {
  constructor () {
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

  componentWillUnmount () {
    clearTimeout(this._closeTimout)
  }

  check () {
    this.setState({
      open: true,
      checking: true,
      errors: [],
      errorIndex: 0,
    }, () => this._check())
  }

  _check () {
    const node = this.props.getBody()
    const errors = []
    if (node) {
      dom.walk(node, (child) => {
        for (let rule of rules) {
          if (!rule.test(child)) {
            errors.push({ node: child, rule })
          }
        }
      }, () => {
        this.setState({ errors, checking: false }, this.firstError)
        if (errors.length === 0) {
          this._closeTimout = setTimeout(this.handleClose, 3000)
        }
      })
    }
  }

  firstError () {
    if (this.state.errors.length > 0) {
      this.setErrorIndex(0)
    }
  }

  nextError () {
    const next = (this.state.errorIndex + 1) % this.state.errors.length
    this.setErrorIndex(next)
  }

  prevError () {
    const len = this.state.errors.length
    const prev = (len + this.state.errorIndex - 1) % len
    this.setErrorIndex(prev)
  }

  setErrorIndex (errorIndex) {
    this.onLeaveError()
    this.setState({ errorIndex }, this.selectCurrent)
  }

  selectCurrent () {
    const errorNode = this.errorNode()
    if (errorNode) {
      this.getFormState()
      dom.select(errorNode)
    } else {
      this.firstError()
    }
  }

  error () {
    return this.state.errors[this.state.errorIndex]
  }

  errorNode () {
    const error = this.error()
    return error && error.node
  }

  errorRule () {
    const error = this.error()
    return error && error.rule
  }

  errorMessage () {
    const rule = this.errorRule()
    return rule && rule.message()
  }

  getFormState () {
    const rule = this.errorRule()
    const node = this.errorNode()
    if (rule && node) {
      this.setState({ formState: rule.data(node), formStateValid: false })
    }
  }

  updateFormState ({target}) {
    const formState = Object.assign({}, this.state.formState)
    formState[target.name] = target.value
    this.setState({
      formState,
      formStateValid: this.formStateValid(formState)
    })
  }

  formStateValid (formState) {
    formState = formState || this.state.formState
    const node = this.tempNode()
    const rule = this.errorRule()
    if (!node || !rule) {
      return false
    }
    rule.update(node, formState)
    return rule.test(node)
  }

  fixIssue (ev) {
    ev.preventDefault()
    const rule = this.errorRule()
    const node = this.errorNode()
    if (rule && node) {
      this.removeTempNode()
      rule.update(node, this.state.formState)
      if (rule.test(node)) {
        this.removeError()
      }
    }
  }

  tempNode () {
    if (!this._tempNode) {
      const node = this.errorNode()
      if (node) {
        this._tempNode = node.cloneNode(true)
        const parent = node.parentNode
        parent.insertBefore(this._tempNode, node)
        parent.removeChild(node)
      }
    }
    return this._tempNode
  }

  removeTempNode () {
    const node = this.errorNode()
    if (this._tempNode && node) {
      const parent = this._tempNode.parentNode
      parent.insertBefore(node, this._tempNode)
      parent.removeChild(this._tempNode)
      this._tempNode = null
    }
  }

  onLeaveError () {
    this.removeTempNode()
  }

  removeError () {
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

  handleClose () {
    this.onLeaveError()
    this.setState({ open: false })
  }

  render () {
    const rule = this.errorRule()
    return <Tray
      label={formatMessage('Accessibility Checker')}
      isDismissable
      isOpen={this.state.open}
      onRequestClose={this.handleClose}
      placement="end"
      closeButtonLabel={formatMessage('Close Accessibility Checker')}
    >
      <Container
        as="div"
        style={{width: '20rem'}}
        padding="medium"
       >
        <Heading level="h3" as="h2" margin="medium 0" color="brand">
          <IconCompleteSolid style={{
            verticalAlign: 'middle',
            paddingBottom: '0.1em'
          }} />
          {' ' + formatMessage('Accessibility Checker')}
        </Heading>
        { this.state.errors.length > 0 &&
          <Container as="div">
            <Typography size="small">
              {formatMessage('Issue { num } of { total }', {
                num: this.state.errorIndex + 1,
                total: this.state.errors.length
              })}
            </Typography>
            <form onSubmit={this.fixIssue}>
              <Container as="div" margin="x-small 0 medium">
                <Grid vAlign="middle" hAlign="space-between" colSpacing="none">
                  <GridRow>
                    <GridCol>
                      <Button onClick={this.prevError}>{formatMessage('Prev')}</Button>{' '}
                      <Button onClick={this.nextError} variant="primary">{formatMessage('Next')}</Button>
                    </GridCol>
                    <GridCol width="auto">
                      <Button
                        type="submit"
                        variant="success"
                        disabled={!this.state.formStateValid}
                      >
                        {formatMessage('Apply Fix')}
                      </Button>
                    </GridCol>
                  </GridRow>
                </Grid>
              </Container>
              <Alert variant="warning">{this.errorMessage()}</Alert>
              { rule.form().map((f) => <Container as="div" key={f.dataKey} margin="medium 0 0">
                {this.renderField(f)}
              </Container>) }
            </form>
            <Container as="div" margin="large 0 0">
              <Heading level="h4" as="h3" padding="0 0 x-small">
                <IconQuestionSolid style={{
                  verticalAlign: 'middle',
                  paddingBottom: '0.1em'
                }} />
                {' ' + formatMessage('Why')}
              </Heading>
              <Typography size="small">
                {rule.why() + ' '}
                <Link href={rule.link} target="_blank">{formatMessage('Learn more')}</Link>
              </Typography>
            </Container>
          </Container>
        }
        { this.state.errors.length === 0 && !this.state.checking &&
          <Alert variant="success">
            {formatMessage('No accessibility issues were detected.')}
          </Alert>
        }
        { this.state.checking && 
          <Spinner
            margin="medium auto"
            title={formatMessage('Checking for accessibility issues')}
          />
        }
      </Container>
    </Tray>
  }

  renderField (f) {
    if (f.options) {
      return <Select
        label={f.label}
        name={f.dataKey}
        value={this.state.formState[f.dataKey]}
        onChange={this.updateFormState}
        >
        { f.options.map((o) =>
          <option value={o[0]}>{o[1]}</option>
        )}
      </Select>
    } else if (f.color) {
      return <ColorField
        label={f.label}
        name={f.dataKey}
        value={this.state.formState[f.dataKey]}
        onChange={this.updateFormState}
      />
    } else {
      return <TextInput
        label={f.label}
        name={f.dataKey}
        value={this.state.formState[f.dataKey]}
        onChange={this.updateFormState}
      />
    }
  }
}

module.exports = Checker