import React from 'react'
import ReactDOM from 'react-dom'
import i18n from 'i18n!react_collaborations'
  class DeleteConfirmation extends React.Component {
    componentDidMount () {
      ReactDOM.findDOMNode(this).focus()
    }

    render () {
      return (
        <div className='DeleteConfirmation' tabIndex='0'>
          <p className='DeleteConfirmation-message'>
            {i18n.t('Remove "%{collaborationTitle}"?', {
              collaborationTitle: this.props.collaboration.title
            })}
          </p>
          <div className='DeleteConfirmation-actions'>
            <button className='Button Button--danger' onClick={this.props.onDelete}>
              {i18n.t('Yes, remove')}
            </button>
            <button className='Button' onClick={this.props.onCancel}>
              {i18n.t('Cancel')}
            </button>
          </div>
        </div>
      )
    }
  };

  DeleteConfirmation.propTypes = {
    collaboration: React.PropTypes.object,
    onCancel: React.PropTypes.func,
    onDelete: React.PropTypes.func
  }

export default DeleteConfirmation
