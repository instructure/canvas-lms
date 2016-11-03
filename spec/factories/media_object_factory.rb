module Factories
  def media_object(opts={})
    mo = MediaObject.new
    mo.media_id = opts[:media_id] || "1234"
    mo.media_type = opts[:media_type] || "video"
    mo.context = opts[:context] || @course
    mo.user = opts[:user] || @user
    mo.save!
    mo
  end
end
