define([
  'react',
  'react-dom',
  'redux',
  'react-redux',
  'compiled/util/natcompare',
  './store',
  './actions',
  './reducer',
  './components/add_people',
], (React, ReactDOM, redux, { connect, Provider }, natcompare,
    { createStore, defaultState }, { actions, actionTypes }, reducer, AddPeople) => {
  class AddPeopleApp {
    constructor (root, props) {
      this.root = root;                     // DOM node we render into
      this.closer = this.close.bind(this);  // close us
      this.onCloseCallback = props.onClose; // tell our parent
      this.theme = props.theme || 'canvas';


      // natural sort the sections by name
      let sections = props.sections || [];
      sections = sections.slice().sort(natcompare.byKey('name'));

      // create the store with its initial state
      // some values are default, some come from props
      this.store = createStore(reducer, {
        courseParams: {
          courseId: props.courseId || 0,
          defaultInstitutionName: props.defaultInstitutionName || '',
          roles: props.roles || [],
          sections,
          inviteUsersURL: props.inviteUsersURL
        },
        inputParams: {
          searchType: defaultState.inputParams.searchType,
          nameList: defaultState.inputParams.nameList,
          role: props.roles.length ? props.roles[0].id : '',
          section: sections.length ? sections[0].id : '',
          canReadSIS: props.canReadSIS
        },
        apiState: defaultState.apiState,
        userValidationResult: defaultState.userValidationResult,
        usersToBeEnrolled: defaultState.usersToBeEnrolled
      });

      // when ConnectedApp is rendered, these state members are passed as props
      function mapStateToProps (state) {
        return { ...state };
      }


      // when ConnectedApp is rendered, all the action dispatch functions are passed as props
      const mapDispatchToProps = dispatch => redux.bindActionCreators(actions, dispatch)

      // connect our top-level component to redux
      this.ConnectedApp = connect(mapStateToProps, mapDispatchToProps)(AddPeople);
    }
    open () {
      this.render(true);
    }
    close () {
      this.render(false);
      if (typeof this.onCloseCallback === 'function') {
        this.onCloseCallback();
      }
    }
    // used by the roster page to decide if it has to requry for the course's
    // enrollees
    usersHaveBeenEnrolled () {
      return this.store.getState().usersEnrolled;
    }
    unmount () {
      ReactDOM.unmountComponentAtNode(this.root);
    }
    render (isOpen) {
      const ConnectedApp = this.ConnectedApp;
      ReactDOM.render(
        <Provider store={this.store}>
          <ConnectedApp isOpen={isOpen} onClose={this.closer} theme={this.theme} />
        </Provider>,
        this.root
      )
    }
  }
  return AddPeopleApp;
});
