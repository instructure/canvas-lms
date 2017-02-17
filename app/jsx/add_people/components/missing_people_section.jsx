define([
  'i18n!roster',
  'react',
  './shapes',
  'instructure-ui'
], (I18n, React, shapes, {Table, ScreenReaderContent,
      TextInput, Checkbox, Link}) => {
  const namePrompt = I18n.t('Click to add a name');
  const nameLabel = I18n.t("New user's name");
  const emailLabel = I18n.t('Required Email Address');

  function eatEvent (event) {
    event.stopPropagation();
    event.preventDefault();
  }

  class MissingPeopleSection extends React.Component {
    static propTypes = {
      missing: React.PropTypes.shape(shapes.missingsShape).isRequired,
      searchType: React.PropTypes.string.isRequired,
      inviteUsersURL: React.PropTypes.string,
      onChange: React.PropTypes.func.isRequired
    };
    static defaultProps = {
      inviteUsersURL: undefined
    }

    // event handlers ------------------------------------
    // user has chosen to create a new user for this group of duplicates
    onSelectNewForMissing = (event) => {
      eatEvent(event);
      const address = event.target.value || event.target.getAttribute('data-address');
      const missingUser = this.props.missing[address];
      let defaultEmail = '';
      if (this.props.searchType === 'cc_path') {
        defaultEmail = missingUser.address;
      }
      const newUserInfo = {
        name: (missingUser.newUserInfo && missingUser.newUserInfo.name) || '',
        email: (missingUser.newUserInfo && missingUser.newUserInfo.email) || defaultEmail
      };

      // user may have clicked on the link. if so, put focus on the adjacent checkbox
      if (!(event.target.tagName === 'input' && event.target.getAttribute('type') === 'checkbox')) {
        const checkbox = event.target.parentElement.parentElement.querySelector('input[type="checkbox"]');
        checkbox.focus();
      }

      if (typeof this.props.onChange === 'function') {
        this.props.onChange(address, newUserInfo);
      }
    }
    // when either of the TextInputs for creating a new user for a missing person
    // changes, we come here collect the input
    // @param event: the event that triggered the change
    onNewForMissingChange = (event) => {
      const field = event.target.getAttribute('name');
      const address = event.target.getAttribute('data-address');
      const newUserInfo = this.props.missing[address].newUserInfo;
      newUserInfo[field] = event.target.value;
      this.props.onChange(address, newUserInfo);
    }
    // when user unchecks a checked new user
    // @param address: the address field of this user
    // @param event: the click event
    onUncheckUser = (event) => {
      const address = event.target.value;
      this.props.onChange(address, false);
    }
    // send the current list of users on up
    onChangeUsers () {
      const userList = this.state.candidateUsers.filter(u => (
        u.checked && u.email && u.name
      ));
      this.props.onChange(userList);
    }


    // rendering ------------------------------------
    // render each of the missing login ids or sis ids
    // @returns an array of table rows, one for each missing id
    renderMissingIds () {
      const missingList = this.props.missing;

      return Object.keys(missingList).map((missingKey) => {
        const missing = missingList[missingKey];
        let row;

        // a row for each login_id
        if (!this.props.inviteUsersURL) {
          // cannot create new users. Just show the missing ones
          row = (
            <tr key={`missing_${missing.address}`}>
              <td>{missing.address}</td>
            </tr>
          );
        } else if (missing.createNew) {
          row = (
            <tr key={`missing_${missing.address}`} >
              <td>
                <Checkbox
                  value={missing.address} checked onChange={this.onUncheckUser}
                  label={<ScreenReaderContent>{I18n.t('Check to skip adding a user for %{loginid}',
                                                {loginid: missing.address})}</ScreenReaderContent>}
                />
              </td>
              <td>
                <TextInput
                  required
                  name="name"
                  type="text"
                  placeholder={nameLabel}
                  label={<ScreenReaderContent>{nameLabel}</ScreenReaderContent>}
                  data-address={missing.address}
                  onChange={this.onNewForMissingChange}
                />
              </td>
              <td>
                <TextInput
                  required
                  name="email"
                  type="email"placeholder={emailLabel}
                  label={<ScreenReaderContent>{emailLabel}</ScreenReaderContent>}
                  data-address={missing.address}
                  onChange={this.onNewForMissingChange}
                />
              </td>
              <td>{missing.address}</td>
            </tr>
          );
        } else {
          row = (
            <tr key={`missing_${missing.address}`}>
              <td>
                <Checkbox
                  value={missing.address} checked={false} onClick={this.onSelectNewForMissing}
                  label={<ScreenReaderContent>{I18n.t('Check to add a user for %{loginid}',
                                                  {loginid: missing.address})}</ScreenReaderContent>}
                />
              </td>
              <td colSpan="2">
                <Link onClick={this.onSelectNewForMissing} data-address={missing.address}>
                  {namePrompt}
                </Link>
              </td>
              <td>{missing.address}</td>
            </tr>
          );
        }
        return row;
      });
    }
    // render each of the missing email addresses
    // @returns an array of table rows, one for each missing id
    renderMissingEmail () {
      const missingList = this.props.missing;

      return Object.keys(missingList).map((missingKey) => {
        const missing = missingList[missingKey];
        let row;
        if (!this.props.inviteUsersURL) {
          // cannot create new users. Just show the missing ones
          row = (
            <tr key={`missing_${missing.address}`}>
              <td>{missing.address}</td>
            </tr>
          );
        } else if (missing.createNew) {
          row = (
            <tr key={`missing_${missing.address}`} >
              <td>
                <Checkbox
                  value={missing.address} checked onChange={this.onUncheckUser}
                  label={<ScreenReaderContent>{I18n.t('Check to skip adding a user for %{loginid}',
                                                    {loginid: missing.address})}</ScreenReaderContent>}
                />
              </td>
              <td>
                <TextInput
                  required
                  name="name"
                  type="text"
                  placeholder={nameLabel}
                  label={<ScreenReaderContent>{nameLabel}</ScreenReaderContent>}
                  data-address={missing.address}
                  onChange={this.onNewForMissingChange}
                />
              </td>
              <td>{missing.address}</td>
            </tr>
          );
        } else {
          row = (
            <tr key={`missing_${missing.address}`} checked={false}>
              <td>
                <Checkbox
                  value={missing.address} checked={false} onChange={this.onSelectNewForMissing}
                  label={<ScreenReaderContent>{I18n.t('Check to add a user for %{loginid}',
                                                {loginid: missing.address})}</ScreenReaderContent>}
                />
              </td>
              <td>
                <Link onClick={this.onSelectNewForMissing} data-address={missing.address}>
                  {namePrompt}
                </Link>
              </td>
              <td>{missing.address}</td>
            </tr>
          );
        }
        return row;
      });
    }

    renderTableHead () {
      let idColHeader = null;
      if (this.props.searchType === 'unique_id') {
        idColHeader = <th scope="col">{I18n.t('Login ID')}</th>;
      } else if (this.props.searchType === 'sis_user_id') {
        idColHeader = <th scope="col">{I18n.t('SIS ID')}</th>
      }

      if (this.props.inviteUsersURL) {
        return (
          <thead>
            <tr>
              <th scope="col">
                <ScreenReaderContent>{I18n.t('User Selection')}</ScreenReaderContent>
              </th>
              <th scope="col">{I18n.t('Name')}</th>
              <th scope="col">{I18n.t('Email Address')}</th>
              {idColHeader}
            </tr>
          </thead>
        );
      }
      idColHeader = idColHeader || <th scope="col">{I18n.t('Email Address')}</th>;
      return (
        <thead>
          <tr>{idColHeader}</tr>
        </thead>
      );
    }
    // render the list of login_ids where we did not find users
    render () {
      return (
        <div className="addpeople__missing namelist">
          <Table caption={<ScreenReaderContent>{I18n.t('Unmatched login list')}</ScreenReaderContent>}>
            {this.renderTableHead()}
            <tbody>
              {this.props.searchType === 'cc_path' ? this.renderMissingEmail() : this.renderMissingIds()}
            </tbody>
          </Table>
        </div>
      );
    }
  }

  return MissingPeopleSection;
});
