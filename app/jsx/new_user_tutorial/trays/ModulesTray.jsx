define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
  'jsx/shared/SVGWrapper'
], (React, I18n, { Heading, Typography }, SVGWrapper) => {
  const ModulesTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Modules')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Organize your course content')}
      </Typography>
      <Typography as="p">
        {
            I18n.t(`Organize and segment your course by topic, unit, chapter,
                    or week. Sequence select modules by defining criteria and
                    prerequisites.`)
          }
      </Typography>
      <div className="ModulesTutorialTray__ImageContainer">
        <SVGWrapper url="/images/module_tutorial.svg" />
      </div>
    </div>
  );

  return ModulesTray;
});
