import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import Heading from 'instructure-ui/lib/components/Heading'

  const PeopleTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('People')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Add Students, TAs, and Observers to your course')}
      </Typography>
      <Typography as="p">
        {
          I18n.t('Manage enrollment status, create groups, and add users from this page.')
        }
      </Typography>
    </div>
  );

export default PeopleTray
