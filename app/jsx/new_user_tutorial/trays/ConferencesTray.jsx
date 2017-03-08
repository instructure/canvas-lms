define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
  const ConferencesTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Conferences')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Virtual lectures in real-time')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Conduct virtual lectures, virtual office hours, and student
            groups. Broadcast real-time audio and video, share presentation
            slides, give demonstrations of applications and online resources,
            and more.`)
        }
      </Typography>
    </div>
  );

  return ConferencesTray;
});
