class QuizQuestion::MatchGroup
  def initialize(matches = [])
    build_matches(matches)
  end

  def add(properties)
    return if has_text?(properties[:text])

    match_id = properties[:match_id] || generate_id
    match = Match.new(properties[:text], match_id)
    matches.push(match) unless matches.include?(match)
  end

  def matches
    @matches ||= []
  end

  def to_a
    matches.map { |match| match.to_hash }
  end

  private
  def build_matches(matches)
    matches.each { |m| add(m) }
  end

  def has_text?(text)
    matches.detect { |m| m.text == text }
  end

  def has_id?(id)
    matches.detect { |m| m.id == id }
  end

  def generate_id
    proposed_id = id_generator
    while has_id?(proposed_id)
      proposed_id = id_generator
    end
    proposed_id
  end

  def id_generator
    rand(10_000)
  end


  class Match
    include Comparable

    attr_reader :text, :id

    def initialize(text, id)
      @text, @id = text, id
    end

    def <=>(other)
      id <=> other.id
    end

    def to_hash
      { text: text, match_id: id }
    end
  end
end


