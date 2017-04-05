class LinkedinExport < ActiveRecord::Base

  belongs_to :user
  attr_accessible :linkedin_id, :first_name, :last_name, :maiden_name, :email_address, :location, :industry, :job_title, :num_connections, :num_connections_capped, :summary, :specialties, :public_profile_url, :last_modified_timestamp, :associations, :interests, :publications, :patents, :languages, :skills, :certifications, :educations, :most_recent_school, :graduation_year, :major, :courses, :volunteer, :three_current_positions, :current_employer, :three_past_positions, :num_recommenders, :recommendations_received, :following, :job_bookmarks, :honors_awards

end
