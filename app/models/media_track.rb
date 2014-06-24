class MediaTrack < ActiveRecord::Base
  belongs_to :user
  belongs_to :media_object, :touch => true
  validates_presence_of :media_object_id, :content
  attr_accessible :user_id, :kind, :locale, :content

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :media_object_id, :kind, :locale, :content, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:user, :media_object]
end
