define([
  'react',
  'i18n!react_collaborations',
  'compiled/str/splitAssetString'
], (React, I18n, splitAssetString) => {
  class GettingStartedCollaborations extends React.Component {
    renderContent() {
      let header, content, link;
      let [context, contextId] = splitAssetString((ENV.PARENT_CONTEXT && ENV.PARENT_CONTEXT.context_asset_string) || ENV.context_asset_string)
      const url = `/${context}/${contextId}/settings/configurations`;


      if (this.props.ltiCollaborators.ltiCollaboratorsData.length === 0) {
        if (ENV.current_user_roles.indexOf("teacher") !== -1) {
          header = I18n.t('No LTIs Configured')
          content = I18n.t('There are no Configured LTIs that interact with collaborations.')
          link = <a rel="external" href={url}>{I18n.t('Set some up now')}</a>
        }
        else{
          header = I18n.t('No LTIs Configured')
          content = I18n.t('You have no LTIs configured to create collaborations with. Talk to your teacher to get some set up.')
          link = null
        }
      }
      else {
        header = I18n.t('Getting started with Collaborations')
        content = I18n.t('Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by clicking on the "+ Collaboration" button.')
        link = <a href="https://community.canvaslms.com/docs/DOC-2627">{I18n.t('Learn more about collaborations')}</a>
      }
      return (
        <div>
          <h3 className="ic-Action-header__Heading">{header}</h3>
          <p>
            {content}
          </p>
          {link}
        </div>
      )
    }

    render () {
      return (
        <div className="GettingStartedCollaborations">
          <div className="image-collaborations-container">
            <img className="image-collaborations" src="/images/svg-icons/icon-collaborations.svg"/>
          </div>
          <div className="Collaborations--GettingStarted">
            {this.renderContent()}
          </div>
        </div>
      )
    }
  };

  return GettingStartedCollaborations;
});
