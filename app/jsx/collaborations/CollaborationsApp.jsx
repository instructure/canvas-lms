define([
  'react',
  'react-modal',
  'jsx/collaborations/GettingStartedCollaborations',
  'jsx/collaborations/CollaborationsNavigation',
  './CollaborationsList',
  './store/store'
], (React, Modal, GettingStartedCollaborations, CollaborationsNavigation, CollaborationsList, {dispatch}) => {
  class CollaborationsApp extends React.Component {
    constructor (props) {
      super(props);
    }

    static propTypes: {
      applicationState: React.PropTypes.object,
      actions: React.PropTypes.object
    }

    componentWillReceiveProps (nextProps) {
      let { createCollaborationPending, createCollaborationSuccessful } = nextProps.applicationState.createCollaboration
    }

    render () {
      let { list } = this.props.applicationState.listCollaborations;

      return (
        <div className='CollaborationsApp'>
          <CollaborationsNavigation
            ltiCollaborators={this.props.applicationState.ltiCollaborators}
          />
          {list.length
            ? <CollaborationsList collaborationsState={this.props.applicationState.listCollaborations} getCollaborations={this.props.actions.getCollaborations} deleteCollaboration={this.props.actions.deleteCollaboration} />
            : <GettingStartedCollaborations ltiCollaborators={this.props.applicationState.ltiCollaborators}/>
          }
        </div>
      );
    }
  };

  return CollaborationsApp;
});
