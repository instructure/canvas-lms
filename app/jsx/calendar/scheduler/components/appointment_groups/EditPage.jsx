define([
  'react',
  'i18n!appointment_groups',
], (React, I18n) => {

  class FindAppointment extends React.Component {

    static propTypes = {
      appointment_group: React.PropTypes.shape({
        title: React.PropTypes.string
      })
    };

    render () {
      return (
        <h1>
          {I18n.t('Edit %{pageTitle}', {
            pageTitle: this.props.appointment_group.title
          })}
        </h1>
      );
    }
  }

  return FindAppointment;
});
