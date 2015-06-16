define({
  PROGRESS_ATTRS: [
    'id',
    'completion',
    'url', // for polling
    'workflow_state'
  ],

  ATTACHMENT_ATTRS: [
    'created_at',
    'url'
  ],

  PROGRESS_QUEUED: 'queued',
  PROGRESS_ACTIVE: 'running',
  PROGRESS_COMPLETE: 'completed',
  PROGRESS_FAILED: 'failed',

  KC_RETURN: 13,
});