define([
  'react',
  'i18n!react_collaborations',
], function (React, I18n) {
  class NewCollaborationsDropDown extends React.Component {
    render () {
      return (
        <div className="al-dropdown__container create-collaborations-dropdown">
          <button className="al-trigger Button Button--primary" aria-label={I18n.t('Add Collaboration')} role="button" href="#">{I18n.t('+ Collaboration')}</button>
          <ul className="al-options" role="menu" tabIndex="0" aria-hidden="true" aria-expanded="false" aria-activedescendant="new-collaborations-dropdown">
            {
              this.props.ltiCollaborators.map(ltiCollaborator =>{
                return(
                  <li key={ltiCollaborator.id}>
                    <a href="#" tabIndex="0" role="menuitem">{ltiCollaborator.name}</a>
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
