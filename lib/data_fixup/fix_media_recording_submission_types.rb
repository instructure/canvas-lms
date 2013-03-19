module DataFixup
  module FixMediaRecordingSubmissionTypes
    def self.run
      date = Date.strptime(Setting.get('media_recording_type_bad_date', '03/08/2013'), '%m/%d/%Y')
      Assignment.where("updated_at > ? AND submission_types LIKE '%online_media_recording%'", date).find_each do |assign|
        assign.submission_types = assign.submission_types.gsub('online_media_recording', 'media_recording')
        assign.save!
      end
    end
  end
end
