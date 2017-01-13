class Bookmarks::Bookmark < ActiveRecord::Base
  acts_as_list scope: :user_id
  def data
    json ? JSON.parse(json) : nil
  end

  def data=(data)
    self.json = data.to_json
  end

  def as_json
    super(include_root: false, except: [:json, :user_id]).merge({data: data})
  end
end
