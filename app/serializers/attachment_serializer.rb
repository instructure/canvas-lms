class AttachmentSerializer < Canvas::APISerializer
  include Api::V1::Attachment

  root :attachment

  def_delegators :@controller,
    :lock_explanation,
    :thumbnail_image_url,
    :file_download_url

  def initialize(object, options)
    super(object, options)

    %w[ current_user current_pseudonym quota quota_used ].each do |ivar|
      instance_variable_set "@#{ivar}", @controller.instance_variable_get("@#{ivar}")
    end
  end

  def serializable_object(options={})
    attachment_json(object, current_user)
  end
end
