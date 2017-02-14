define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
  const HomeTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Home')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('This is your course landing page!')}
      </Typography>
      <Typography as="p">
        {
          I18n.t("When people visit your course, this is the first page they'll see. " +
                "We've set your home page to Modules, but you have the option to change it.")
        }
      </Typography>
    </div>
  );

  return HomeTray;
});
