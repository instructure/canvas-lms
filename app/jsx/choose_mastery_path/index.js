import React from 'react'
import ReactDOM from 'react-dom'
import { bindActionCreators } from 'redux'
import { connect, Provider } from 'react-redux'
import createStore from './store'
import actions from './actions'
import ChooseMasteryPath from './components/choose-mastery-path'

export default {
    init: (data, root) => {
      const options = data.options
      delete data.options

      const store = createStore(data)
      const boundActions = bindActionCreators(actions, store.dispatch)

      boundActions.setOptions(options)

      const ConnectedApp = connect((state) => ({
        options: state.options,
        selectedOption: state.selectedOption,
      }))(ChooseMasteryPath)

      ReactDOM.render(
        <Provider store={store}>
          <ConnectedApp
            selectOption={boundActions.selectOption}
          />
        </Provider>,
        root
      )
    },
  }
