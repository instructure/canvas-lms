module SimpleStats
  def variance(items, type = :population)
    return 0 if items.size < 2
    divisor = type == :population ? items.length : items.length - 1
    mean = items.sum / items.length.to_f
    sum = items.map{ |item| (item - mean) ** 2 }.sum
    (sum / divisor).to_f
  end
  module_function :variance
end
