require 'hash_view'
require 'formatted_type'

class ObjectPartView < HashView
  attr_reader :name, :part

  # 'part' is a hash of name/example pairs, e.g.
  # { "name": "Sheldon Cooper", "email": "sheldon@caltech.example.com" }
  def initialize(name, part)
    @name = name
    @part = part
  end

  def guess_type(example)
    FormattedType.new(example).to_hash
  end

  def property_pairs
    @property_pairs ||=
      @part.map do |name, example|
        [
          name,
          guess_type(example)
        ]
      end
  end

  def properties
    Hash[property_pairs]
  end
end