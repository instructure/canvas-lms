define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
  const ImportTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Import')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Bring your content into your course')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Bring existing content from another course or course
            management system into your Canvas course.`)
        }
      </Typography>
    </div>
  );

  return ImportTray;
});
