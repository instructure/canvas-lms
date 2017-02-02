define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
  const DiscussionsTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Discussions')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Encourage class participation')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Create as many discussion topics as needed, as assignments
            for grading or as a forum for shared ideas and information.`)
        }
      </Typography>
    </div>
  );

  return DiscussionsTray;
});
