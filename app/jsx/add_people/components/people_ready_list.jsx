define([
  'i18n!roster',
  'react',
  './shapes',
  'instructure-ui'
], (I18n, React, {personReadyToEnrollShape},
    {Alert, Table, ScreenReaderContent}) => {
  class PeopleReadyList extends React.Component {
    static propTypes = {
      nameList: React.PropTypes.arrayOf(React.PropTypes.shape(personReadyToEnrollShape)),
      defaultInstitutionName: React.PropTypes.string,
      canReadSIS: React.PropTypes.bool
    };
    static defaultProps = {
      nameList: [],
      defaultInstitutionName: '',
      canReadSIS: true
    };

    renderNotice () {
      return (
        this.props.nameList.length > 0
          ? <Alert variant="success" isDismissable={false}>{I18n.t('The following users are ready to be added to the course.')}</Alert>
          : <Alert variant="info" isDismissable={false}>{I18n.t('No users were selected to add to the course')}</Alert>
      );
    }
    renderUserTable () {
      let userTable = null;
      if (this.props.nameList.length > 0) {
        userTable = (
          <Table caption={<ScreenReaderContent>{I18n.t('User list')}</ScreenReaderContent>}>
            <thead>
              <tr>
                <th>{I18n.t('Name')}</th>
                <th>{I18n.t('Email Address')}</th>
                <th>{I18n.t('Login ID')}</th>
                {this.props.canReadSIS ? <th>{I18n.t('SIS ID')}</th> : null}
                <th>{I18n.t('Institution')}</th>
              </tr>
            </thead>
            <tbody>
              {this.props.nameList.map((n, i) => (
                <tr key={`${n.address}_${i}`}>
                  <td>{n.user_name}</td>
                  <td>{n.email}</td>
                  <td>{n.login_id || ''}</td>
                  {this.props.canReadSIS ? <td>{n.sis_user_id || ''}</td> : null}
                  <td>{n.account_name || this.props.defaultInstitutionName}</td>
                </tr>
              ))}
            </tbody>
          </Table>
        );
      }
      return userTable;
    }

    render () {
      return (
        <div className="addpeople__peoplereadylist">
          <div className="peoplereadylist__pad-box">
            {this.renderNotice()}
          </div>
          {this.renderUserTable()}
        </div>
      );
    }
  }

  return PeopleReadyList;
});
