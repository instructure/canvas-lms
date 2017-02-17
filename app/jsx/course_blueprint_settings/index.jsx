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
      this.store = createStore({
        accountId: ENV.accountId,
        course: ENV.course,
        terms: ENV.terms,
        subAccounts: ENV.subAccounts,
      })
      const boundActions = bindActionCreators(actions, this.store.dispatch)

      this.ConnectedApp = connect((state) => {
        const props = [
          'courses',
          'terms',
          'subAccounts',
          'errors',
          'isLoadingCourses',
        ].reduce((propSet, prop) => Object.assign(propSet, { [prop]: state[prop] }), {})
        props.loadCourses = boundActions.loadCourses
        return props
      })(BlueprintSettings)
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
