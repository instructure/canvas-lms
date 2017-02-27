define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/Heading',
  '../shapes/course',
  '../shapes/subAccount',
  '../shapes/term',
], (I18n, React, {default: Heading}, courseShape, subAccountShape, termShape) => {
  const { arrayOf } = React.PropTypes

  return class BlueprintSettings extends React.Component {
    static propTypes = {
      course: courseShape.isRequired,
      terms: arrayOf(termShape).isRequired,
      subAccounts: arrayOf(subAccountShape).isRequired,
    }

    render () {
      return (
        <div className="bpc__wrapper">
          <Heading level="h2">{I18n.t('Blueprint Settings')}</Heading>
          <br />
          <Heading level="h3" border="bottom">{I18n.t('Associated Courses')}</Heading>
        </div>
      )
    }
  }
})
