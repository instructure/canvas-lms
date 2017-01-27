import React from 'react'
import Modal from 'react-modal'
import GettingStartedCollaborations from 'jsx/collaborations/GettingStartedCollaborations'
import CollaborationsNavigation from 'jsx/collaborations/CollaborationsNavigation'
import CollaborationsList from './CollaborationsList'
import LoadingSpinner from './LoadingSpinner'
import { dispatch } from './store/store'

  class CollaborationsApp extends React.Component {
    constructor (props) {
      super(props);
    }

    static propTypes = {
      applicationState: React.PropTypes.object,
      actions: React.PropTypes.object
    }

    componentWillReceiveProps (nextProps) {
      let { createCollaborationPending, createCollaborationSuccessful } = nextProps.applicationState.createCollaboration
    }

    render () {
      let { list } = this.props.applicationState.listCollaborations;
      let isLoading = this.props.applicationState.listCollaborations.listCollaborationsPending
                      || this.props.applicationState.ltiCollaborators.listLTICollaboratorsPending

      return (
        <div className='CollaborationsApp'>
          {isLoading
            ? <LoadingSpinner />
            : <div>
                <CollaborationsNavigation
                  ltiCollaborators={this.props.applicationState.ltiCollaborators}
                />
                {list.length
                  ? <CollaborationsList collaborationsState={this.props.applicationState.listCollaborations} getCollaborations={this.props.actions.getCollaborations} deleteCollaboration={this.props.actions.deleteCollaboration} />
                  : <GettingStartedCollaborations ltiCollaborators={this.props.applicationState.ltiCollaborators}/>
                }
              </div>
          }
        </div>
      );
    }
  };

export default CollaborationsApp
