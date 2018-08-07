require 'bullet'

Bullet.enable = true
Bullet.unused_eager_loading_enable = false
Bullet.counter_cache_enable = false

Bullet.rails_logger = true
Bullet.raise = true
Bullet.stacktrace_excludes = [
  # chains to root_topic, but it should be cached fairly often, so we don't want
  # to unnecessarily preload
  ['app/models/discussion_topic.rb', 'low_level_locked_for?'],
  # impossible to know what should be preloaded ahead-of-time, and we only process
  # messages one-at-a-time anyway
  ['app/models/message.rb', 'infer_defaults'],
  ['app/models/message.rb', 'parse!'],
  # Accessing only one item of a collection
  ['lib/grade_calculator.rb', 'compute_course_scores_from_weighted_grading_periods?'],
  # Some weirdness in the spec only
  'spec/migrations/reassociate_conversation_attachments_spec.rb',
]

# keep track of Bullet objects consistently in the face of sharding
Object.prepend(Module.new do
  def bullet_key
    Shard.default.activate { super }
  end
end)
