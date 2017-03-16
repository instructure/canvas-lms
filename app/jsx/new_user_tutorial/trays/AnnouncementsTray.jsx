define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
  const AnnouncementsTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Announcements')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Share important updates with users')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Share important information with all users in your course.
            Choose to get a copy of your own announcements in Notifications.`)
        }
      </Typography>
    </div>
  );

  return AnnouncementsTray;
});
