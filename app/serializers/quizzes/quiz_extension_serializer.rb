module Quizzes
  class QuizExtensionSerializer < Canvas::APISerializer
    root :quiz_extension

    attributes :user_id, :quiz_id, :user_id, :extra_attempts, :extra_time,
               :manually_unlocked, :end_at
  end
end

