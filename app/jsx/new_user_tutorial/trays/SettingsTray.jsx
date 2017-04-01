define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
  const AssignmentsTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Settings')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Manage your course details')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Update and view sections, course details, navigation, feature
                  options and external app integrations, all visible only to Instructors.`)
        }
      </Typography>
    </div>
  );

  return AssignmentsTray;
});
