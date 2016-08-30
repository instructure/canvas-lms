define([
  'react',
  'react-dom',
  'react-redux',
  './components/breakdown-graphs',
  './components/sticky-sidebar',
  './components/breakdown-details',
], (React, ReactDOM, { connect, Provider }, BreakdownGraphs, StickySidebar, BreakdownDetails) => {
  const Graphs = connect((state) => ({
    assignment: state.assignment,
    ranges: state.ranges,
    enrolled: state.enrolled,
    isLoading: state.isLoading,
  }))(BreakdownGraphs)

  const Sidebar = connect((state) => ({
    isHidden: !state.showDetails,
  }))(StickySidebar)

  const Details = connect((state) => ({
    selectedPath: state.selectedPath,
    ranges: state.ranges,
    assignment: state.assignment,
  }))(BreakdownDetails)

  return class CRSApp {
    constructor (actions) {
      this.actions = actions
    }

    renderGraphs (store, root) {
      const actions = {
        selectRange: this.actions.selectRange,
      }

      ReactDOM.render(
        <Provider store={store}>
          <Graphs {...actions} />
        </Provider>,
        root
      )
    }

    renderDetails (store, root) {
      const detailActions = {
        selectRange: this.actions.selectRange,
        selectStudent: this.actions.selectStudent,
      }

      ReactDOM.render(
        <Provider store={store}>
          <Sidebar
            closeSidebar={this.actions.closeSidebar}
          >
            <Details {...detailActions} />
          </Sidebar>
        </Provider>,
        root
      )
    }
  }
})
