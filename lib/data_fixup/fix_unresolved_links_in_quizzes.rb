module DataFixup
  module FixUnresolvedLinksInQuizzes
    def self.run
      Quizzes::Quiz.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        Quizzes::Quiz.where(id: min_id..max_id).where("quiz_data like ?", "%LINK.PLACEHOLDER%").find_each do |quiz|
          quiz.generate_quiz_data
          quiz.save
        end
      end
    end
  end
end
