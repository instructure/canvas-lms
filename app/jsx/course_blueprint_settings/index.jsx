define([
  'react',
  'react-dom',
  'redux',
  'react-redux',
  './store',
  './actions',
  './components/BlueprintSettings',
], (React, ReactDOM, { bindActionCreators }, { connect, Provider }, createStore, actions, BlueprintSettings) => {
  class BlueprintSettingsApp {
    constructor (ENV, root) {
      this.root = root
      this.store = createStore()
      const boundActions = bindActionCreators(actions, this.store.dispatch)

      this.ConnectedApp = connect(state => ({
        // TODO: connect state to props
      }))(BlueprintSettings)
    }

    unmount () {
      ReactDOM.unmountComponentAtNode(this.root)
    }

    render () {
      const ConnectedApp = this.ConnectedApp
      ReactDOM.render(
        <Provider store={this.store}>
          <ConnectedApp />
        </Provider>,
        this.root
      )
    }
  }

  return BlueprintSettingsApp
})
