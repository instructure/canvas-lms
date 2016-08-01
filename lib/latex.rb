module Latex
  def self.to_math_ml(latex:)
    Latex::MathMl.new(latex: latex).parse
  end
end
