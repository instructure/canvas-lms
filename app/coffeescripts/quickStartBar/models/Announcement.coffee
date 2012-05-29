define ['compiled/quickStartBar/models/Discussion'], (Discussion) ->

  class Announcement extends Discussion

    defaults:
      is_announcement: true

