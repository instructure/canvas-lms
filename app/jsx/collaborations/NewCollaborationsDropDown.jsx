define([
  'react',
  'i18n!react_collaborations',
  'compiled/str/splitAssetString',
], function (React, I18n, splitAssetString) {
  class NewCollaborationsDropDown extends React.Component {
    constructor (props) {
      super(props);
      this.openModal = this.openModal.bind(this)
    }

    openModal (e, itemUrl) {
      e.preventDefault()
      this.props.onItemClicked(itemUrl)
    }

    render () {
      let [context, contextId] = splitAssetString(ENV.context_asset_string)
      return (
        <div className="al-dropdown__container create-collaborations-dropdown">
          <button className="al-trigger Button Button--primary" aria-label={I18n.t('Add Collaboration')} role="button" href="#">{I18n.t('+ Collaboration')}</button>
          <ul className="al-options" role="menu" tabIndex="0" aria-hidden="true" aria-expanded="false" aria-activedescendant="new-collaborations-dropdown">
            {
              this.props.ltiCollaborators.map(ltiCollaborator => {
                let itemUrl = `/${context}/${contextId}/external_tools/${ltiCollaborator.id}?launch_type=collaboration`
                return(
                  <li key={ltiCollaborator.id}>
                    <a
                      href={itemUrl}
                      rel="external"
                      role="menuitem"
                      onClick={(e) => this.openModal(e, `${itemUrl}&display=borderless`)}
                    >
                      {ltiCollaborator.name}
                    </a>
                  </li>
                )
              })
            }
          </ul>
        </div>
      )
    }
  };

  return NewCollaborationsDropDown;
});
