define([
  'i18n!roster',
  'react',
  './shapes',
  'instructure-ui/Table',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/TextInput',
  'instructure-ui/Checkbox',
  'instructure-ui/Link'
], (I18n, React, shapes, {default: Table}, {default: ScreenReaderContent},
    {default: TextInput}, {default: Checkbox}, {default: Link}) => {
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

    constructor (props) {
      super(props);

      this.state = {
        selectAll: false
      };
      this.tbodyNode = null;
    }

    componentWillReceiveProps (nextProps) {
      const all = Object.keys(nextProps.missing).every(m => nextProps.missing[m].createNew)
      this.setState({selectAll: all});
    }

    // event handlers ------------------------------------
    // user has chosen to create a new user for this group of duplicates
    onSelectNewForMissing = (event) => {
      eatEvent(event);

      // user may have clicked on the link. if so, put focus on the adjacent checkbox
      if (!(event.target.tagName === 'INPUT' && event.target.getAttribute('type') === 'checkbox')) {
        // The link was rendered with the attribute data-address=address for this row.
        // Use it to find the checkbox with the matching value.
        const checkbox = this.tbodyNode.querySelector(`input[type="checkbox"][value="${event.target.getAttribute('data-address')}"]`);
        if (checkbox) {
          checkbox.focus();
        }
      }
      const address = event.target.value || event.target.getAttribute('data-address');
      this.onSelectNewForMissingByAddress(address);
    }

    onSelectNewForMissingByAddress (address) {
      const missingUser = this.props.missing[address];
      let defaultEmail = '';
      if (this.props.searchType === 'cc_path') {
        defaultEmail = missingUser.address;
      }
      const newUserInfo = {
        name: (missingUser.newUserInfo && missingUser.newUserInfo.name) || '',
        email: (missingUser.newUserInfo && missingUser.newUserInfo.email) || defaultEmail
      };

      if (typeof this.props.onChange === 'function') {
        this.props.onChange(address, newUserInfo);
      }
    }

    // check or uncheck all the missing users' checkboxes
    onSelectNewForMissingAll = (event) => {
      this.setState({selectAll: event.target.checked});
      if (event.target.checked) {
        Object.keys(this.props.missing).forEach(address => this.onSelectNewForMissingByAddress(address));
      } else {
        Object.keys(this.props.missing).forEach(address => this.onUncheckUserByAddress(address));
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
    // @param event: the click event
    onUncheckUser = (event) => {
      this.onUncheckUserByAddress(event.target.value);
      this.setState({selectAll: false});
    }
    onUncheckUserByAddress = (address) => {
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
                  value={missing.newUserInfo.name || null}
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
                <Checkbox
                  id="missing_users_select_all"
                  value="__ALL__"
                  checked={this.state.selectAll}
                  onChange={this.onSelectNewForMissingAll}
                  label={<ScreenReaderContent>{I18n.t('Check to select all')}</ScreenReaderContent>}
                />
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
            <tbody ref={(n) => { this.tbodyNode = n; }} >
              {this.props.searchType === 'cc_path' ? this.renderMissingEmail() : this.renderMissingIds()}
            </tbody>
          </Table>
        </div>
      );
    }
  }

  return MissingPeopleSection;
});
