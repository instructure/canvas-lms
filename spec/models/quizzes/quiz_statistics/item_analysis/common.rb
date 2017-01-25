# like be_within, but also works on arrays/hashes that have reals
class BeApproximately
  def initialize(expected, tolerance)
    @expected = expected
    @tolerance = tolerance
  end

  def matches?(target)
    @target = target
    approximates?(@target, @expected)
  end

  def approximates?(target, expected)
    return true  if target == expected
    return false unless target.class == expected.class
    case target
    when Array; array_approximates(target, expected)
    when Hash;  hash_approximates(target, expected)
    when Integer,
         Float; real_approximates(target, expected)
    else        false
    end
  end

  def array_approximates(target, expected)
    target.size == expected.size &&
    target.map.with_index.all? { |value, index|
      approximates?(target[index], expected[index])
    }
  end

  def hash_approximates(target, expected)
    target.keys.sort == expected.keys.sort &&
    target.keys.all? { |key|
      approximates?(target[key], expected[key])
    }
  end

  def real_approximates(target, expected)
    (target - expected).abs <= @tolerance
  end

  def failure_message
    "expected #{@target.inspect} to be approximately #{@expected}"
  end

  def failure_message_when_negated
    "expected #{@target.inspect} not to be approximately #{@expected}"
  end
end

def be_approximately(expected, tolerance = 0.01)
  BeApproximately.new(expected, tolerance)
end

# set up a quiz with graded submissions. supports T/F and multiple
# choice questions
#
# * answer_key is an array of correct answers (one of [A-DFT])
# * each submission is an array of a student's submitted answers
#
# question types are inferred from the correct answer, and multiple
# choice questions always have four possibilities
#
# note that you can specify point values for each question by
# providing an array for each answer (e.g. ["A", 2] instead of just "A")
def simple_quiz_with_submissions(answer_key, *submissions)
  opts = submissions.last.is_a?(Hash) ? submissions.pop : {}
  questions = answer_key.each_with_index.map { |answer, i|
    points = 1
    answer, points = answer if answer.is_a?(Array)
    true_false = answer == 'T' || answer == 'F'
    type = true_false ? 'true_false_question' : 'multiple_choice_question'
    answers = (true_false ? ['T', 'F'] : 'A'..'D').each_with_index.map do |a, j|
      {:answer_text => a, :answer_weight => (a == answer ? 100 : 0), :id => (4 * i + j)}
    end

    {:question_data => {:name => "question #{i + 1}", :points_possible => points, :question_type => type, :answers => answers}}
  }
  assignment_quiz(questions, opts)
  students = create_users_in_course(@quiz.context, submissions.size, return_type: :record)
  submissions.each_with_index do |data, i|
    sub = @quiz.generate_submission(students[i])
    sub.mark_completed
    sub.submission_data = Hash[data.each_with_index.map{ |answer, i|
      matched_answer = @questions[i].question_data[:answers].detect{ |a| a[:text] == answer}
      ["question_#{@questions[i].id}", matched_answer ? matched_answer[:id].to_s : nil]
    }]
    Quizzes::SubmissionGrader.new(sub).grade_submission
  end
  @quiz.reload
end

def simple_quiz_with_shuffled_answers(answer_key, *submissions)
  opts = submissions.last.is_a?(Hash) ? submissions.pop : {}
  questions = answer_key.each_with_index.map { |answer, i|
    points = 1
    answer, points = answer if answer.is_a?(Array)
    true_false = answer == 'T' || answer == 'F'
    type = true_false ? 'true_false_question' : 'multiple_choice_question'
    answers = (true_false ? ['T', 'F'] : 'A'..'D').each_with_index.map do |a, j|
      {:answer_text => a, :answer_weight => (a == answer ? 100 : 0), :id => (4 * i + j)}
    end
    {:question_data => {:name => "question #{i + 1}", :points_possible => points, :question_type => type, :answers => answers}}
  }

  assignment_quiz(questions, opts)
  @quiz.shuffle_answers = true
  @quiz.save!

  students = create_users_in_course(@quiz.context, submissions.size, return_type: :record)
  submissions.each_with_index do |data, i|
    sub = @quiz.generate_submission(students[i])
    sub.mark_completed
    sub.submission_data = Hash[data.each_with_index.map{ |answer, i|
      answer = {"T" => "True", "F" => "False"}[answer] || answer
      matched_answer = @questions[i].question_data[:answers].detect{ |a| a[:text] == answer}
      ["question_#{@questions[i].id}", matched_answer ? matched_answer[:id].to_s : nil]
    }]
    Quizzes::SubmissionGrader.new(sub).grade_submission
  end
  @quiz.reload
end
