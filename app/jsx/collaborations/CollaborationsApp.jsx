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
      $(window).on('externalContentReady', (e, data) => dispatch(props.actions.externalContentReady(e, data)));

      this.state = { isModalOpen: false }
      this.openModal = this.openModal.bind(this)
    }

    static propTypes: {
      applicationState: React.PropTypes.object,
      actions: React.PropTypes.object
    }

    componentWillReceiveProps (nextProps) {
      let { createCollaborationPending, createCollaborationSuccessful } = nextProps.applicationState.createCollaboration

      if (!createCollaborationPending && createCollaborationSuccessful) {
        this.setState({
          isModalOpen: false
        })
      }
    }

    openModal (url) {
      this.setState({
        isModalOpen: true,
        modalUrl: url
      })
    }

    render () {
      let { list } = this.props.applicationState.listCollaborations;

      return (
        <div className='CollaborationsApp'>
          <CollaborationsNavigation
            ltiCollaborators={this.props.applicationState.ltiCollaborators}
            onItemClicked={this.openModal} />

          {list.length
            ? <CollaborationsList collaborationsState={this.props.applicationState.listCollaborations} getCollaborations={this.props.actions.getCollaborations} deleteCollaboration={this.props.actions.deleteCollaboration} openModal={this.openModal} />
            : <GettingStartedCollaborations ltiCollaborators={this.props.applicationState.ltiCollaborators}/>
          }
          <Modal
            className='CollaborationsModal'
            isOpen={this.state.isModalOpen}
          >
            <iframe className='Collaborations-iframe' src={this.state.modalUrl}></iframe>
          </Modal>
        </div>
      );
    }
  };

  return CollaborationsApp;
});
