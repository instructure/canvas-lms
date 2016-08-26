define([
  'react',
  'i18n!custom_help_link',
  './CustomHelpLinkIconInput',
  'jsx/shared/icons/IconCog',
  'jsx/shared/icons/IconFolder',
  'jsx/shared/icons/IconInformation',
  'jsx/shared/icons/IconLifePreserver',
  'jsx/shared/icons/IconQuestionMark'
], function(
    React,
    I18n,
    CustomHelpLinkIconInput,
    IconCog,
    IconFolder,
    IconInformation,
    IconLifePreserver,
    IconQuestionMark) {
  const CustomHelpLinkIcons = React.createClass({
    propTypes: {
      defaultValue: React.PropTypes.string
    },
    render () {
      const {
        defaultValue
      } = this.props
      return (
        <fieldset className="ic-Fieldset ic-Fieldset--radio-checkbox">
          <legend className="ic-Legend">
            { I18n.t('Icon') }
          </legend>
          <div className="ic-Form-control ic-Form-control--radio ic-Form-control--radio-inline">
            <CustomHelpLinkIconInput
              value="help"
              defaultChecked={defaultValue === 'help'}
              label={I18n.t('Question mark icon')}>
              <IconQuestionMark />
            </CustomHelpLinkIconInput>

            <CustomHelpLinkIconInput
              value="information"
              defaultChecked={defaultValue === 'information'}
              label={I18n.t('Information icon')}>
              <IconInformation />
            </CustomHelpLinkIconInput>

            <CustomHelpLinkIconInput
              value="folder"
              defaultChecked={defaultValue === 'folder'}
              label={I18n.t('Folder icon')}>
              <IconFolder />
            </CustomHelpLinkIconInput>

            <CustomHelpLinkIconInput
              value="cog"
              defaultChecked={defaultValue === 'cog'}
              label={I18n.t('Cog icon')}>
              <IconCog />
            </CustomHelpLinkIconInput>

            <CustomHelpLinkIconInput
              value="lifepreserver"
              defaultChecked={defaultValue === 'lifepreserver'}
              label={I18n.t('Life preserver icon')}>
              <IconLifePreserver />
            </CustomHelpLinkIconInput>
          </div>
        </fieldset>
      )
    }
  });

  return CustomHelpLinkIcons;
});
