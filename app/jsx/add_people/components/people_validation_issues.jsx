define([
  'i18n!roster',
  'react',
  './shapes',
  './duplicate_section',
  './missing_people_section',
  'instructure-ui'
], (I18n, React, shapes, DuplicateSection, MissingPeopleSection, {Alert}) => {
  class PeopleValidationIssues extends React.Component {
    static propTypes = {
      searchType: React.PropTypes.string.isRequired,
      duplicates: React.PropTypes.shape(shapes.duplicatesShape),
      missing: React.PropTypes.shape(shapes.missingsShape),
      onChangeDuplicate: React.PropTypes.func.isRequired,
      onChangeMissing: React.PropTypes.func.isRequired
    };

    static defaultProps = {
      duplicates: {},
      missing: {}
    };

    constructor (props) {
      super(props);

      this.state = {
        newUsersForMissing: {},
        focusElem: null
      }
    }
    componentDidUpdate () {
      if (this.state.focusElem) {
        this.state.focusElem.focus();
      }
    }


    // event handlers ------------------------------------
    // our user chose one from a set of duplicates
    // @param address: the address searched for that returned duplicate canvas users
    // @param user: the user data for the one selected
    onSelectDuplicate = (address, user) => {
      this.props.onChangeDuplicate({address, selectedUserId: user.user_id});
    }
    // our user chose to create a new canvas user rather than select one of the duplicate results
    // @param address: the address searched for that returned duplicate canvas users
    // @param newUserInfo: the new canvas user data entered by our user
    onNewForDuplicate = (address, newUserInfo) => {
      this.props.onChangeDuplicate({address, newUserInfo});
    }
    // our user chose to skip this searched for address
    // @param address: the address searched for that returned duplicate canvas users
    onSkipDuplicate = (address) => {
      this.props.onChangeDuplicate({address, skip: true});
    }
    // when the MissingPeopleSection changes,
    // it sends us the current list
    // @param address: the address searched for
    // @param newUserInfo: the new person user wants to invite, or false if skipping
    onNewForMissing = (address, newUserInfo) => {
      this.props.onChangeMissing({address, newUserInfo});
    }


    // rendering ------------------------------------
    // render the duplicates sections
    renderDuplicates () {
      const duplicateAddresses = this.props.duplicates && Object.keys(this.props.duplicates);
      if (!duplicateAddresses || duplicateAddresses.length === 0) {
        return null;
      }
      return (
        <div className="peopleValidationissues__duplicates">
          <Alert variant="warning" isDismissable={false}>
            {I18n.t('There were several possible matches with the import. Please resolve them below.')}
          </Alert>
          {duplicateAddresses.map((address) => {
            const dupeSet = this.props.duplicates[address];
            return (
              <DuplicateSection
                key={`dupe_${address}`}
                duplicates={dupeSet}
                onSelectDuplicate={this.onSelectDuplicate}
                onNewForDuplicate={this.onNewForDuplicate}
                onSkipDuplicate={this.onSkipDuplicate}
              />
            )
          })}
        </div>
      );
    }
    // render the missing section
    renderMissing () {
      const missingAddresses = this.props.missing && Object.keys(this.props.missing);
      if (!missingAddresses || missingAddresses.length === 0) {
        return null;
      }
      const alertText = this.props.searchType === 'unique_id'
          ? I18n.t('We were unable to find matches for the logins below. Select which you would like to be created as new users.')
          : I18n.t('Unable to find matches for these email addresses in your institution. Select those you would like to create as new users. Unselected will be skipped.'); // eslint-disable-line max-len
      return (
        <div className="peoplevalidationissues__missing">
          <Alert variant="warning" isDismissable={false}>{alertText}</Alert>
          <MissingPeopleSection
            missing={this.props.missing}
            searchType={this.props.searchType}
            onChange={this.onNewForMissing}
          />
        </div>
      );
    }
    render () {
      return (
        <div className="addpeople__peoplevalidationissues">
          {this.renderDuplicates()}
          {this.renderMissing()}
        </div>
      );
    }
  }

  return PeopleValidationIssues;
});
