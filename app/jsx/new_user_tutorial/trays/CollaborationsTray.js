define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
  const CollaborationsTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Collaborations')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Work and create together')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Provide a space for users to work on a single Google Doc
            simultaneously, from within your Canvas course.`)
        }
      </Typography>
    </div>
  );

  return CollaborationsTray;
});
