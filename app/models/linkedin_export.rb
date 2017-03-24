class LinkedinExport < ActiveRecord::Base

  belongs_to :user
  attr_accessible :linkedin_id, :first_name, :last_name, :maiden_name, :email_address, :location, :industry, :num_connections, :num_connections_capped, :summary, :specialties, :public_profile_url, :last_modified_timestamp, :associations, :interests, :publications, :patents, :languages, :skills, :certifications, :educations, :courses, :volunteer, :three_current_positions, :three_past_positions, :num_recommenders, :recommendations_received, :following, :job_bookmarks, :honors_awards

end
