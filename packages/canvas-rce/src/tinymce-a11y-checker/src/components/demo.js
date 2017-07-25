const React = require('react')
const Checker = require('./checker')

class Demo extends React.Component {
  constructor () {
    super()
    this.state = { node: null }
    this.handleCheck = this.handleCheck.bind(this)
  }

  componentDidMount () {
    this.setState({ node: this._body })
  }

  handleCheck () {
    if (this._checker) {
      this._checker.check()
    }
  }

  render () {
    return <div>
      <button onClick={this.handleCheck}>Check Accessability</button>
      <div ref={r => this._body = r}>
        <h1>Test Document</h1>
        <img src="http://lorempixel.com/output/animals-q-c-640-480-6.jpg" alt=""/>
        <table>
          <tr>
            <td>1</td>
            <td>2</td>
            <td>3</td>
          </tr>
        </table>
        <a href="https://github.com/instructure">Instructure GitHub</a>
      </div>
      <Checker
        ref={ref => this._checker = ref}
        node={this.state.node}
        doc={window.document}
      />
    </div>
  }
}

module.exports = Demo