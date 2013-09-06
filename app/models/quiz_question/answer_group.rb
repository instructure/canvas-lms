class QuizQuestion::AnswerGroup
  attr_accessor :answers, :taken_ids

  extend Forwardable
  def_delegators :@answers, :each, :<<, :[], :[]=, :each_with_index


  def initialize(answers = [])
    @answers = answers
    @taken_ids = []
  end

  def set_correct_if_none
    return if @answers.empty?
    @answers[0][:weight] = 100.to_f unless correct_answer
  end

  def map!
    mapped = @answers.map do |a|
      yield self, a
    end

    @answers = mapped
  end

  def correct_answer
    @answers.detect(&:correct?)
  end


  def assign_ids
    @taken_ids = @answers.map do |a|
      a.set_id(@taken_ids)
    end
  end

  def to_a
    @answers.map(&:to_hash)
  end

  def self.generate(question)
    answers = if question[:answers].is_a? Hash
                  question[:answers].reduce([]) do |arr, (key, value)|
                    arr[key.to_i] = value
                    arr
                  end
                else
                  question[:answers] || []
                end

    answers = new(answers)
    question.answers = answers
    question.answer_parser.new(answers).parse(question)
  end

  class Answer
    extend Forwardable
    def_delegators :@data, :[], :[]=

    def initialize(data = {})
      @data = data
    end

    def to_hash
      @data
    end

    def correct?
      @data[:weight].to_i == 100
    end

    def set_id(taken_ids)
      @data[:id] = @data["id"] if @data["id"]
      @data[:id] = nil if (@data[:id] && @data[:id].to_i.zero?) || taken_ids.include?(@data[:id])
      @data[:id] ||= unique_local_id(taken_ids)
      @data[:id]
    end

    def set_match_id(taken_ids)
      @data[:match_id] = @data["match_id"] if @data["match_id"]
      @data[:match_id] = nil if (@data[:match_id] && @data[:match_id].to_i.zero?) || taken_ids.include?(@data[:match_id])
      @data[:match_id] ||= unique_local_id(taken_ids)
      @data[:match_id]
    end

    private

    def unique_local_id(taken_ids = [], suggested_id=nil)
      if suggested_id && suggested_id > 0 && !taken_ids.include?(suggested_id)
        return suggested_id
      end
      id = rand(10000)

      while taken_ids.include?(id)
        id = rand(10000)
      end

      id
    end

  end
end
