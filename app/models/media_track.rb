class MediaTrack < ActiveRecord::Base
  belongs_to :user
  belongs_to :media_object, :touch => true
  validates_presence_of :media_object_id, :content

end
