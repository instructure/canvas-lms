module Latex
  def self.to_math_ml(latex:)
    return "" unless latex.present?
    Latex::MathMl.new(latex: latex).parse
  end
end
