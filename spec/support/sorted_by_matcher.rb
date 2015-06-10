RSpec::Matchers.define :be_sorted_by do |attr|
  match do |records|
    a = records.map{ |record| record.fetch(attr) }
    a.sort == a
  end
end
