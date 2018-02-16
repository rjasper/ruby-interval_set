require 'interval_set'

RSpec.describe IntervalSet do
  I = IntervalSet

  context '#[]' do
    it 'returns an IntervalSet' do
      expect(I[]).to be_an_instance_of(I)
      expect(I[1..2]).to be_an_instance_of(I)
      expect(I[1...2, 3...4]).to be_an_instance_of(I)
    end

    it 'returns an empty IntervalSet' do
      expect(I[]).to be_empty
    end
  end

  context '#min #max and #bounds' do
    it 'has no bounds when empty' do
      expect(I[].min).to be_nil
      expect(I[].max).to be_nil
      expect(I[].bounds).to be_nil
    end

    it 'has matching bounds with range' do
      i = I[1...2]

      expect(i.min).to eq(1)
      expect(i.max).to eq(2)
    end

    it 'updates min after removal' do
      i = I[0...2]

      i >> (0...1)

      expect(i.min).to eq(1)
      expect(i.max).to eq(2)
    end

    it 'updates max after removal' do
      i = I[0...2]

      i >> (1...2)

      expect(i.min).to eq(0)
      expect(i.max).to eq(1)
    end

    it 'has no bounds after complete removal' do
      i = I[0...1]

      i >> (0...1)

      expect(i.min).to be_nil
      expect(i.max).to be_nil
    end

    it 'initializes bounds' do
      tree_map = TreeMap.new
      tree_map.put(0, 0...1)
      tree_map.put(2, 2...3)

      I2 = Class.new(I) do
        public :initialize_with_range_map
      end

      i = I2.allocate.initialize_with_range_map(tree_map)

      expect(i.min).to eq(0)
      expect(i.max).to eq(3)
      expect(i.bounds).to eq(0...3)
    end
  end

  context '#eql?' do
    it 'does not equal nil' do
      expect(I[0...1]).to_not eq(nil)
    end

    it 'does not equal unexpected object' do
      expect(I[0...1]).to_not eq(1)
    end

    it 'equals self' do
      set = I[0...1]

      expect(set).to eq(set)
    end

    it 'equals other interval sets' do
      expect(I[]).to eq(I[])
      expect(I[0...1]).to eq(I[0...1])
      expect(I[0...1, 2...3]).to eq(I[0...1, 2...3])
      expect(I[0...1, 1...2]).to eq(I[0...2])
    end

    it 'does not equal other interval sets' do
      expect(I[0...1]).to_not eq(I[])
      expect(I[]).to_not eq(I[0...1])
      expect(I[0...2]).to_not eq(I[0...1])
    end
  end

  context '#eql set?' do
    it 'equals empty ranges' do
      expect(I[]).to be_eql_set(0...0)
      expect(I[]).to be_eql_set(1...0)
    end

    it 'equals ranges' do
      expect(I[]).to be_eql_set(1...0)
      expect(I[0...1]).to be_eql_set(0...1)
    end

    it 'does not equal ranges' do
      expect(I[]).to_not be_eql_set(0...1)
      expect(I[0...1]).to_not be_eql_set(1...0)
      expect(I[0...1]).to_not be_eql_set(0...2)
    end
  end

  context '#empty?' do
    it 'is empty' do
      expect(I[]).to be_empty
    end

    it 'is not empty' do
      expect(I[0...1]).to_not be_empty
    end
  end

  context '#to_s' do
    it 'converts to string when empty' do
      expect(I[].to_s).to eq('[]')
    end

    it 'converts to string' do
      expect(I[1...2, 3...4].to_s).to eq('[1...2, 3...4]')
    end
  end

  context '#copy' do
    it 'copies empty' do
      original = I[]
      copy = I[]

      copy = copy.copy(original)

      expect(copy).to be_empty
      expect(copy).to_not be_equal(original)
    end

    it 'copies non empty' do
      original = I[0...1]
      copy = I[]

      copy.copy(original)

      expect(copy).to eq(I[0...1])
      expect(copy).to_not be_equal(original)
    end

    it 'clears data on copy' do
      original = I[0...1]
      copy = I[2...3]

      copy.copy(original)

      expect(copy).to eq(I[0...1])
      expect(copy).to_not be_equal(original)
    end
  end

  context '#clone' do
    it 'clones empty' do
      original = I[]

      clone = original.clone

      expect(clone).to be_empty
      expect(clone).to_not be_equal(original)
    end

    it 'clones non empty' do
      original = I[0...1]

      clone = original.clone

      expect(clone).to eq(I[0...1])
      expect(clone).to_not be_equal(original)
    end
  end

  context '#subset?' do
    it 'is subset' do
      expect(I[1...2]).to be <= (1...2) # both exact
      expect(I[1...2]).to be <= (0...2) # right exact
      expect(I[1...2]).to be <= (1...3) # left exact
      expect(I[1...2]).to be <= (0...3) # both extra

      expect(I[]).to be <= (1...0)
      expect(I[]).to be <= (0...1)
      expect(I[0...1]).to be <= (0...1)
      expect(I[1...2]).to be <= (0...3)

      expect(I[]).to be <= I[]
      expect(I[]).to be <= I[0...1]
      expect(I[0...1]).to be <= I[0...1]
      expect(I[1...2]).to be <= I[0...3]
    end

    it 'is not subset' do
      expect(I[0...1]).to_not be <= (1...0)
      expect(I[0...1]).to_not be <= (2...3)

      expect(I[0...1]).to_not be <= I[]
      expect(I[0...1]).to_not be <= I[2...3]

      expect(I[1...2]).to_not be <= (0...1) # on left
      expect(I[1...2]).to_not be <= (2...3) # on right
      expect(I[1...2]).to_not be <= (1...1.5) # not right
      expect(I[1...2]).to_not be <= (1.5...2) # not left
      expect(I[1...2]).to_not be <= (2...1) # reversed
    end
  end

  context '#superset?' do
    it 'is a superset of an empty range when empty' do
      # reversed ranges are interpreted as empty
      expect(I[]).to be >= (0...0)
      expect(I[]).to be >= (1...0)
    end

    it 'is not superset of proper range when empty' do
      expect(I[]).to_not be >= (0...1)
    end

    it 'is superset of range' do
      i = I[0...1, 2...3]

      expect(i).to be >= (0...1)
      expect(i).to be >= (0.5...1)
      expect(i).to be >= (0...0.5)
      expect(i).to be >= (0.25...0.75)
      expect(i).to be >= (2...3)
      expect(i).to be >= (1...0)
    end

    it 'is not superset of range' do
      i = I[0...1, 2...3]

      expect(i).to_not be >= (-2...-1)
      expect(i).to_not be >= (-1...0)
      expect(i).to_not be >= (-1...0.5)
      expect(i).to_not be >= (-1...1)
      expect(i).to_not be >= (-1...1.5)
      expect(i).to_not be >= (-1...2)
      expect(i).to_not be >= (1...4)
      expect(i).to_not be >= (1.5...4)
      expect(i).to_not be >= (2...4)
      expect(i).to_not be >= (2.5...4)
      expect(i).to_not be >= (3...4)
      expect(i).to_not be >= (5...6)
      expect(i).to_not be >= (0...3)
    end

    it 'is a superset' do
      expect(I[]).to be >= I[]
      expect(I[]).to_not be >= I[0...1]
      expect(I[0...1]).to be >= I[]

      expect(I[1...2, 3...4]).to be >= I[1...2]
      expect(I[1...2, 3...4]).to be >= I[3...4]
      expect(I[1...2, 3...4]).to be >= I[1...2, 3...4]

      expect(I[]).to be >= I[]
      expect(I[0...1]).to be >= I[]
      expect(I[0...1]).to be >= I[0...1]
      expect(I[0...3]).to be >= I[1...2]
    end

    it 'is not superset' do
      expect(I[1...2, 3...4]).to_not be >= I[0...3]
      expect(I[1...2, 3...4]).to_not be >= I[1...2, 3...4, 5...6]

      expect(I[]).to_not be >= I[0...1]
      expect(I[2...3]).to_not be >= I[0...1]
    end
  end

  context '#proper_subset?' do
    it 'is proper subset' do
      expect(I[]).to be < I[0...1]
      expect(I[1...2]).to be < I[0...3]
    end

    it 'is not proper subset' do
      expect(I[]).to_not be < I[]
      expect(I[0...1]).to_not be < I[]
      expect(I[0...1]).to_not be < I[0...1]
      expect(I[0...1]).to_not be < I[2...3]
    end
  end

  context '#proper_superset?' do
    it 'is proper superset' do
      expect(I[0...1]).to be > I[]
      expect(I[0...3]).to be > I[1...2]
    end

    it 'is not proper superset' do
      expect(I[]).to_not be > I[]
      expect(I[]).to_not be > I[0...1]
      expect(I[0...1]).to_not be > I[0...1]
      expect(I[2...3]).to_not be > I[0...1]
    end
  end

  context '#include?' do
    it 'does not include nil' do
      expect(I[]).to_not include(nil)
    end

    it 'includes numbers' do
      i = I[1...2]

      expect(i).to include(1)
      expect(i).to include(1.5)
    end

    it 'does not include numbers' do
      i = I[1...2]

      expect(i).to_not include(0)
      expect(i).to_not include(2)
      expect(i).to_not include(3)
    end
  end

  context '#include_or_limit?' do
    it 'does not include nil' do
      expect(I[]).to_not be_include_or_limit(nil)
    end

    it 'includes numbers' do
      i = I[1...2]

      expect(i).to be_include_or_limit(1)
      expect(i).to be_include_or_limit(1.5)
      expect(i).to be_include_or_limit(2)
    end

    it 'does not include numbers' do
      i = I[1...2]

      expect(i).to_not be_include_or_limit(0)
      expect(i).to_not be_include_or_limit(3)
    end
  end

  context '#intersect?' do
    it 'intersects range' do
      i = I[0...1, 2...3]

      expect(i).to be_intersect(0...1)
      expect(i).to be_intersect(0.5...1)
      expect(i).to be_intersect(0...0.5)
      expect(i).to be_intersect(0.25...0.75)
      expect(i).to be_intersect(2...3)
      expect(i).to be_intersect(-1...0.5)
      expect(i).to be_intersect(-1...1)
      expect(i).to be_intersect(-1...1.5)
      expect(i).to be_intersect(-1...2)
      expect(i).to be_intersect(1...4)
      expect(i).to be_intersect(1.5...4)
      expect(i).to be_intersect(2...4)
      expect(i).to be_intersect(2.5...4)
      expect(i).to be_intersect(0...3)
    end

    it 'not intersects range' do
      i = I[0...1, 2...3]

      expect(i).to_not be_intersect(-2...-1)
      expect(i).to_not be_intersect(-1...0)
      expect(i).to_not be_intersect(3...4)
      expect(i).to_not be_intersect(5...6)
      expect(i).to_not be_intersect(1...0) # reversed range
    end
  end

  context '#bounds_intersected by?' do
    it 'has intersecting bounds' do
      i = I[1...2]

      expect(i).to be_bounds_intersected_by(1...2) # both exact
      expect(i).to be_bounds_intersected_by(0...2) # right exact
      expect(i).to be_bounds_intersected_by(1...3) # left exact
      expect(i).to be_bounds_intersected_by(0...3) # both extra
      expect(i).to be_bounds_intersected_by(1...1.5) # not right
      expect(i).to be_bounds_intersected_by(1.5...2) # not left
    end

    it 'has not intersecting bounds' do
      i = I[1...2]

      expect(i).to_not be_bounds_intersected_by(0...1) # on left
      expect(i).to_not be_bounds_intersected_by(2...3) # on right
      expect(i).to_not be_bounds_intersected_by(1...0) # reversed
    end
  end

  context '#add' do
    it 'does not add empty range' do
      i = I[]
      i << (1...1)

      expect(i).to be_empty
    end

    it 'does not add reversed range' do
      i = I[]
      i << (1...0)

      expect(i).to be_empty
    end

    it 'adds covering range' do
      i = I[1...2]

      expect(i.count).to eq(1)

      i << (0...3)

      expect(i.count).to eq(1)
      expect(i).to eq(I[0...3])
    end

    it 'adds range not within bounds' do
      i = I[1...2]

      expect(i.count).to eq(1)

      i << (3...4)

      expect(i.count).to eq(2)
      expect(i).to eq(I[1...2, 3...4])
    end

    it 'adds subset ranges without effect' do
      i = I[1...2, 3...4, 5...6]

      expect(i.count).to eq(3)

      i << (3...4)

      expect(i.count).to eq(3)
      expect(i).to eq(I[1...2, 3...4, 5...6])
    end

    it 'adds ranges' do
      i = I[]

      i << (0...1)

      expect(i).to eq(I[0...1])
    end

    it 'adds ranges left' do
      i = I[0...1]

      i << (-2...-1)

      expect(i).to eq(I[-2...-1, 0...1])
    end

    it 'adds ranges right' do
      i = I[-2...-1]

      i << (0...1)

      expect(i).to eq(I[-2...-1, 0...1])
    end

    it 'adds ranges left tight' do
      i = I[0...1]

      i << (-2...0)

      expect(i).to eq(I[-2...1])
    end

    it 'adds ranges right tight' do
      i = I[-2...0]

      i << (0...1)

      expect(i).to eq(I[-2...1])
    end

    it 'adds left overlapping' do
      i = I[-1...1]

      i << (-2...0)

      expect(i).to eq(I[-2...1])
    end

    it 'adds right overlapping' do
      i = I[-2...0]

      i << (-1...1)

      expect(i).to eq(I[-2...1])
    end

    it 'adds interval set' do
      i1 = I[0...1, 4...5]
      i2 = I[2...3, 6...7]

      i1 << i2

      expect(i1).to eq(I[0...1, 2...3, 4...5, 6...7])
    end

    it 'adds empty interval set' do
      i1 = I[0...1, 4...5]
      i2 = I[]

      i1 << i2

      expect(i1).to eq(I[0...1, 4...5])
    end

    it 'can add itself' do
      i = I[0...1, 4...5]

      i << i

      expect(i).to eq(I[0...1, 4...5])
    end

    it 'normalizes ranges' do
      expect(I.new.add(0..1).to_a).to eq([0...1,])
    end
  end

  context '#remove' do
    it 'removes from empty' do
      i = I[] >> (1...2)

      expect(i).to be_empty
    end

    it 'does not remove empty range' do
      i = I[0...1]
      i >> (0...0)

      expect(i).to eq(I[0...1])
    end

    it 'does not remove reversed range' do
      i = I[0...1]
      i >> (1...0)

      expect(i).to eq(I[0...1])
    end

    it 'removes left' do
      i = I[0...1] >> (-2...-1)

      expect(i).to eq(I[0...1])
    end

    it 'removes right' do
      i = I[0...1] >> (2...3)

      expect(i).to eq(I[0...1])
    end

    it 'removes tight left' do
      i = I[0...1]

      i >> (-2...0)

      expect(i).to eq(I[0...1])
    end

    it 'removes tight right' do
      i = I[0...1]

      i >> (1...3)

      expect(i).to eq(I[0...1])
    end

    it 'removes left overlap' do
      i = I[0...1]

      i >> (-2...0.5)

      expect(i).to eq(I[0.5...1])
    end

    it 'removes right overlap' do
      i = I[0...1]

      i >> (0.5...3)

      expect(i).to eq(I[0...0.5])
    end

    it 'removes inbetween' do
      i = I[0...1]

      i >> (0.25...0.75)

      expect(i).to eq(I[0...0.25, 0.75...1])
    end

    it 'removes entire set' do
      i = I[0...1]

      i >> (-1...2)

      expect(i).to be_empty
    end

    it 'removes bounds' do
      i = I[0...1]

      i >> (0...1)

      expect(i).to be_empty
    end

    it 'removes interval set' do
      i1 = I[0...2, 3...5]
      i2 = I[1...4, 6...7]

      i1 >> i2

      expect(i1).to eq(I[0...1, 4...5])
    end

    it 'removes itself' do
      i = I[0...1, 4...5]

      i >> i

      expect(i).to be_empty
    end
  end

  context '#clear' do
    it 'clears' do
      i = I[1...2]

      expect(i).to_not be_empty

      i.clear

      expect(i).to be_empty
    end
  end

  context '#intersection' do
    it 'intersects empty' do
      expect(I[] & (0...1)).to be_empty
    end

    it 'does not intersect improper range' do
      expect(I[0...1] & (0...0)).to be_empty
      expect(I[0...1] & (1...0)).to be_empty
    end

    it 'intersects left' do
      expect(I[0...1] & (-2...-1)).to be_empty
    end

    it 'intersects right' do
      expect(I[0...1] & (2...3)).to be_empty
    end

    it 'intersects tight left' do
      expect(I[0...1] & (-2...0)).to be_empty
    end

    it 'intersects tight right' do
      expect(I[0...1] & (1...3)).to be_empty
    end

    it 'intersects left overlap' do
      expect(I[0...1] & (-2...0.5)).to eq(I[0...0.5])
    end

    it 'intersects right overlap' do
      expect(I[0...1] & (0.5...3)).to eq(I[0.5...1])
    end

    it 'intersects inbetween' do
      expect(I[0...1] & (0.25...0.75)).to eq(I[0.25...0.75])
    end

    it 'intersects entire set' do
      expect(I[0...1] & (-1...2)).to eq(I[0...1])
    end

    it 'intersects bounds' do
      expect(I[0...1] & (0...1)).to eq(I[0...1])
    end

    it 'intersects interval set' do
      expect(I[0...2, 3...5] & I[1...4, 6...7]).to eq(I[1...2, 3...4])
    end

    it 'intersects itself' do
      i = I[0...1, 2...3]

      expect(i & i).to eq(I[0...1, 2...3])
    end
  end

  context '#union' do
    it 'unions empty' do
      lhs = I[]
      rhs = I[]

      expect(lhs | rhs).to be_empty
    end

    it 'unions subset ranges without effect' do
      expect(I[0...1] | (2...2)).to eq(I[0...1])
      expect(I[0...1] | (2...1)).to eq(I[0...1])
    end

    it 'unions empty lhs' do
      lhs = I[]
      rhs = I[0...1]

      expect(lhs | rhs).to eq(I[0...1])
    end

    it 'unions empty rhs' do
      lhs = I[0...1]
      rhs = I[]

      expect(lhs | rhs).to eq(I[0...1])
    end

    it 'unions left' do
      expect(I[0...1] | (-2...-1)).to eq(I[-2...-1, 0...1])
    end

    it 'unions right' do
      expect(I[0...1] | (2...3)).to eq(I[0...1, 2...3])
    end

    it 'unions tight left' do
      expect(I[0...1] | (-2...0)).to eq(I[-2...1])
    end

    it 'unions tight right' do
      expect(I[0...1] | (1...3)).to eq(I[0...3])
    end

    it 'unions left overlap' do
      expect(I[0...1] | (-2...0.5)).to eq(I[-2...1])
    end

    it 'unions right overlap' do
      expect(I[0...1] | (0.5...3)).to eq(I[0...3])
    end

    it 'unions inbetween' do
      expect(I[0...1] | (0.25...0.75)).to eq(I[0...1])
    end

    it 'unions entire set' do
      expect(I[0...1] | (-1...2)).to eq(I[-1...2])
    end

    it 'unions bounds' do
      expect(I[0...1] | (0...1)).to eq(I[0...1])
    end

    it 'unions interval set' do
      lhs = I[0...1, 4...5]
      rhs = I[2...3, 6...7]

      expect(lhs | rhs).to eq(I[0...1, 2...3, 4...5, 6...7])
    end

    it 'unions itself' do
      i = I[0...1]

      expect(i | i).to eq(I[0...1])
    end
  end

  context '#difference' do
    it 'differences empty' do
      lhs = I[]
      rhs = I[]

      expect(lhs - rhs).to be_empty
    end

    it 'differences empty ranges without effect' do
      expect(I[0...1] - (2...2)).to eq(I[0...1])
      expect(I[0...1] - (2...1)).to eq(I[0...1])
    end

    it 'differences empty lhs' do
      lhs = I[]
      rhs = I[0...1]

      expect(lhs - rhs).to be_empty
    end

    it 'differences empty rhs' do
      lhs = I[0...1]
      rhs = I[]

      expect(lhs - rhs).to eq(I[0...1])
    end

    it 'differences left' do
      expect(I[0...1] - (-2...-1)).to eq(I[0...1])
    end

    it 'differences right' do
      expect(I[0...1] - (2...3)).to eq(I[0...1])
    end

    it 'differences tight left' do
      expect(I[0...1] - (-2...0)).to eq(I[0...1])
    end

    it 'differences tight right' do
      expect(I[0...1] - (1...3)).to eq(I[0...1])
    end

    it 'differences left overlap' do
      expect(I[0...1] - (-2...0.5)).to eq(I[0.5...1])
    end

    it 'differences right overlap' do
      expect(I[0...1] - (0.5...3)).to eq(I[0...0.5])
    end

    it 'differences inbetween' do
      expect(I[0...1] - (0.25...0.75)).to eq(I[0...0.25, 0.75...1])
    end

    it 'differences entire set' do
      expect(I[0...1] - (-1...2)).to be_empty
    end

    it 'differences bounds' do
      expect(I[0...1] - (0...1)).to be_empty
    end

    it 'differences interval set' do
      lhs = I[0...2, 3...5]
      rhs = I[1...4, 6...7]

      expect(lhs - rhs).to eq(I[0...1, 4...5])
    end

    it 'differences itself' do
      i = I[0...1]

      expect(i - i).to be_empty
    end
  end

  context '#xor' do
    it 'calculates xor' do
      expect(I[] ^ (0..0)).to eq(I[])
      expect(I[0...1] ^ (0..0)).to eq(I[0...1])
      expect(I[] ^ (0..1)).to eq(I[0...1])
      expect(I[0...1] ^ (0..1)).to eq(I[])
      expect(I[0...1] ^ (0..2)).to eq(I[1...2])
      expect(I[0...1] ^ (1..2)).to eq(I[0...2])

      expect(I[] ^ I[]).to eq(I[])
      expect(I[0...1] ^ I[]).to eq(I[0...1])
      expect(I[] ^ I[0...1]).to eq(I[0...1])
      expect(I[0...1] ^ I[0...1]).to eq(I[])
      expect(I[0...1] ^ I[0...2]).to eq(I[1...2])
      expect(I[0...1] ^ I[1...2]).to eq(I[0...2])

      expect(I[0...2, 4...6] ^ I[1...5, 7...8]).to eq(I[0...1, 2...4, 5...6, 7...8])
    end
  end

  context '#shift' do
    it 'shifts numeric' do
      i = I[0...1, 2...3]

      expect(i.shift(1)).to eq(I[1...2, 3...4])
    end
  end

  context '#buffer' do
    it 'buffers range' do
      i = I[0...1, 4...5, 9...10]

      expect(i.buffer(1, 2)).to eq(I[-1...7, 8...12])
    end
  end

  context '#convolve' do
    it 'convolves range' do
      i = I[0...1, 4...5, 9...10]

      expect(i * (-1...2)).to eq(I[-1...7, 8...12])
    end

    it 'convolves reversed range' do
      i = I[0...10, 20...22]

      expect(i * (1...-1)).to be_empty
    end

    it 'convolves interval sets' do
      lhs = I[0...1, 10...12]
      rhs = I[-2...1, 1...2]

      expect(lhs * rhs).to eq(I[-2...3, 8...14])
    end

    it 'convolves empty interval sets' do
      lhs = I[]
      rhs = I[]

      expect(lhs * rhs).to be_empty
    end

    it 'convolves empty lhs interval sets' do
      lhs = I[]
      rhs = I[-2...1, 1...2]

      expect(lhs * rhs).to be_empty
    end

    it 'convolves empty rhs interval sets' do
      lhs = I[0...1, 10...12]
      rhs = I[]

      expect(lhs * rhs).to be_empty
    end
  end

  context 'marshalling' do
    it 'dumps an array' do
      expect(I[1...2, 3...4].marshal_dump).to be == [1...2, 3...4]
    end

    it 'loads from array' do
      interval_set = I.allocate
      interval_set.marshal_load([1...2, 3...4])

      expect(interval_set).to be == I[1...2, 3...4]
    end

    it 'marshals correctly' do
      data = Marshal.dump(I[1...2, 3...4])

      expect(Marshal.load(data)).to be == I[1..2, 3..4]
    end
  end
end