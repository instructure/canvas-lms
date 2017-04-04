import React from 'react'
import ReactDOM from 'react-dom'
import { bindActionCreators } from 'redux'
import { connect, Provider } from 'react-redux'
import createStore from './store'
import actions from './actions'
import BlueprintSettings from './components/BlueprintSettings'

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

    this.ConnectedApp = connect(state =>
      [
        'existingAssociations',
        'addedAssociations',
        'removedAssociations',
        'courses',
        'terms',
        'subAccounts',
        'errors',
        'isLoadingCourses',
        'isLoadingAssociations',
        'isSavingAssociations',
      ].reduce((propSet, prop) => Object.assign(propSet, { [prop]: state[prop] }), {}),
    () => boundActions)(BlueprintSettings)

    // load initial data
    boundActions.loadCourses()
    boundActions.loadAssociations()
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

export default BlueprintSettingsApp
