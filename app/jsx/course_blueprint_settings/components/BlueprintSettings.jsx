define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/Heading',
], (I18n, React, {default: Heading}) => {
  return class BlueprintSettings extends React.Component {
    static propTypes = {

    }

    render () {
      return (
        <div className="bpc__wrapper">
          <Heading>{I18n.t('Blueprint Settings')}</Heading>
        </div>
      )
    }
  }
})
