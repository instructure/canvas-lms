define([
  'react'
], (React) => {
  let main = document.querySelector('#main')

  class CollaborationsToolLaunch extends React.Component {
    constructor (props) {
      super(props)
      this.state = {height: 500}

      this.setHeight = this.setHeight.bind(this)
    }

    componentDidMount () {
      this.setHeight()
      window.addEventListener('resize', this.setHeight)
    }

    componentWillUnMount () {
      window.removeEventListener('resize', this.setHeight)
    }

    setHeight () {
      this.setState({
        height: main.getBoundingClientRect().height - 48
      })
    }

    render () {
      return (
        <div className='CollaborationsToolLaunch' style={{height: this.state.height}}>
          <iframe
            className='tool_launch'
            src={this.props.launchUrl}
          ></iframe>
        </div>
      )
    }
  }

  return CollaborationsToolLaunch
})
