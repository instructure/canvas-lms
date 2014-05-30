class ProgressSerializer < Canvas::APISerializer
  root :progress

  attributes :id, :context_id, :context_type, :user_id, :tag, :completion,
    :workflow_state, :created_at, :updated_at, :message, :url

  def_delegators :@controller, :api_v1_progress_url

  def url
    api_v1_progress_url(object)
  end
end
