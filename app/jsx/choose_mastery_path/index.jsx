define([
  'react',
  'react-dom',
  'redux',
  'react-redux',
  './store',
  './actions',
  './components/choose-mastery-path',
], (React, ReactDOM, { bindActionCreators }, { connect, Provider }, createStore, actions, ChooseMasteryPath) => {
  return {
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
})
