require_relative 'interval_set/version'
require 'treemap-fork'

# IntervalSet implements a set of sorted non-overlapping ranges.
# A range's start is always interpreted as inclusive while the end is exclusive
class IntervalSet
  include Enumerable

  # Builds a new IntervalSet from the supplied ranges. Overlapping ranges will be merged.
  #   IntervalSet[]               # -> []
  #   IntervalSet[0...1]          # -> [0...1]
  #   IntervalSet[0...1, 2...3]   # -> [0...1, 2...3]
  #   IntervalSet[0...1, 1...2]   # -> [0...2]
  #
  #   array = [0...1, 2...3]
  #   IntervalSet[*array]         # -> [0...1, 2...3]
  #
  # @param ranges [Range[]] a list of ranges to be added to the new IntervalSet
  # @return [IntervalSet] a new IntervalSet containing the supplied ranges.
  def self.[](*ranges)
    IntervalSet.new.tap do |interval_set|
      ranges.each {|range| interval_set << range}
    end
  end

  # Returns an empty instance of IntervalSet.
  # @param range_map [TreeMap] a TreeMap of ranges. For internal use only.
  def initialize(range_map = TreeMap.new)
    unless range_map.instance_of?(TreeMap) || range_map.instance_of?(TreeMap::BoundedMap)
      raise ArgumentError.new("invalid range_map #{range_map}")
    end

    @range_map = range_map

    update_bounds
  end

  # Returns +true+ if this IntervalSet contains no ranges.
  def empty?
    @range_map.empty?
  end

  # Returns the lower bound of this IntervalSet.
  #
  #   IntervalSet[0...1, 2...3].min  # -> 0
  #   IntervalSet[].min              # -> nil
  #
  # @return the lower bound or +nil+ if empty.
  def min
    @min
  end

  # Returns the upper bound of this IntervalSet.
  #
  #   IntervalSet[0...1, 2...3].max  # -> 3
  #   IntervalSet[].max              # -> nil
  #
  # @return the upper bound or +nil+ if empty.
  def max
    @max
  end

  # Returns the bounds of this IntervalSet.
  #
  #   IntervalSet[0...1, 2...3].bounds # -> 0...3
  #   IntervalSet[].bounds             # -> nil
  #
  # @return [Range] a range from lower to upper bound or +nil+ if empty.
  def bounds
    empty? ? nil : min...max
  end

  # Returns +true+ if two IntervalSets are equal.
  #
  #   IntervalSet[0...1] == IntervalSet[0...1]  # -> true
  #   IntervalSet[0...1] == IntervalSet[1...2]  # -> false
  #
  # @param other [Object] the other object.
  def eql?(other)
    return false if other.nil? || !other.is_a?(IntervalSet) || count != other.count || bounds != other.bounds

    lhs_iter = enum_for
    rhs_iter = other.enum_for

    count.times.all? {lhs_iter.next == rhs_iter.next}
  end

  alias_method :==, :eql?

  # Returns +true+ if the other object represents a equal
  # set of ranges as this IntervalSet.
  #
  #   IntervalSet[1...2].eql_set?(1...2)           # -> true
  #   IntervalSet[1...2].eql_set?(IntervalSet[1...2]) # -> true
  #
  # @param other [Range | IntervalSet] the other object.
  def eql_set?(other)
    case other
      when Range
        eql_range?(other)
      when IntervalSet
        eql?(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  # Returns +true+ if this IntervalSet contains the given element.
  #
  #   i = IntervalSet[0...1]      # -> [0...1]
  #
  #   i.include?(0)               # -> true
  #   i.include?(0.5)             # -> true
  #   i.include?(1)               # -> false ; a range's end is exclusive
  #
  # Note that the given element must be comparable to elements already in this
  # set. Otherwise, the behavior is undefined.
  #
  # @param element [Object]
  def include?(element)
    return false if element.nil?

    floor_entry = @range_map.floor_entry(element)

    !floor_entry.nil? && floor_entry.value.last > element
  end

  alias_method :===, :include?

  # Returns +true+ if this IntervalSet includes all elements
  # of the other object.
  #
  #   IntervalSet[0...1] >= IntervalSet[0...1]        # -> true
  #   IntervalSet[0...2] >= IntervalSet[0...1]        # -> true
  #   IntervalSet[0...1] >= IntervalSet[0...1, 2...3] # -> false
  #   IntervalSet[0...3] >= IntervalSet[0...1, 2...3] # -> true
  #
  #   # You can also supply ranges
  #   IntervalSet[0...2].superset?(0...1)  # -> true
  #
  # @param other [Range | IntervalSet] the other object.
  def superset?(other)
    case other
      when Range
        superset_range?(other)
      when IntervalSet
        superset_interval_set?(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  alias_method :>=, :superset?

  # Returns +true+ if all elements of this IntervalSet are
  # included by the other object.
  #
  #   IntervalSet[0...1] <= IntervalSet[0...1]        # -> true
  #   IntervalSet[0...1] <= IntervalSet[0...1, 2...3] # -> true
  #   IntervalSet[0...1, 2...3] <= IntervalSet[0...1] # -> false
  #   IntervalSet[0...1, 2...3] <= IntervalSet[0...3] # -> true
  #
  #   # You can also supply ranges
  #   IntervalSet[0...1, 2...3].subset?(0...3)    # -> true
  #
  # @param other [Range | IntervalSet] the other object.
  def subset?(other)
    case other
      when Range
        subset_range?(other)
      when IntervalSet
        other.superset_interval_set?(self)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  alias_method :<=, :subset?

  # Returns +true+ if this IntervalSet is a proper superset of the other.
  #
  #   IntervalSet[0...2] > IntervalSet[0...1] # -> true
  #   IntervalSet[0...2] > IntervalSet[0...2] # -> false
  #   IntervalSet[0...2] > IntervalSet[1...3] # -> false
  #
  #   # Compare to ranges
  #   IntervalSet[0...3].superset?(1...2)  # -> true
  #
  # @param other [Range | IntervalSet] the other object.
  def proper_superset?(other)
    !eql_set?(other) && superset?(other)
  end

  alias_method :>, :proper_superset?

  # Return +true+ if this IntervalSet is a proper subset of the other.
  #
  #   IntervalSet[0...1] < IntervalSet[0...2] # -> true
  #   IntervalSet[1...3] < IntervalSet[0...2] # -> false
  #   IntervalSet[1...3] < IntervalSet[0...2] # -> false
  #
  #   # Compare to ranges
  #   IntervalSet[1...2].subset?(0...3)    # -> false
  #
  # @param other [Range | IntervalSet] the other object.
  def proper_subset?(other)
    !eql_set?(other) && subset?(other)
  end

  alias_method :<, :proper_subset?

  # Returns +true+ if the given range has common elements with the
  # bounding range of this IntervalSet.
  #
  #   IntervalSet[1...2].bounds_intersected_by?(2...3)         # -> false
  #   IntervalSet[1...2, 5...6].bounds_intersected_by?(3...4)  # -> true
  #
  # @param range [Range]
  def bounds_intersected_by?(range)
    return false if IntervalSet.range_empty?(range)

    !empty? && range.first < max && range.last > min
  end

  # Returns +true+ if the given range has common elements with the
  # bounding range or the bounds of this IntervalSet.
  #
  #   IntervalSet[1...2].bounds_intersected_or_touched_by?(2...3)        # -> true
  #   IntervalSet[1...2].bounds_intersected_or_touched_by?(3...4)        # -> false
  #   IntervalSet[1...2, 5...6].bounds_intersected_or_touched_by?(3...4) # -> true
  #
  # @param range [Range]
  def bounds_intersected_or_touched_by?(range)
    return false if IntervalSet.range_empty?(range)

    !empty? && range.first <= max && range.last >= min
  end

  # Returns +true+ if the given object has any common elements with
  # this IntervalSet.
  #
  #   i = IntervalSet[0...1]      # -> [0...1]
  #
  #   # Ranges only need a single common element with the interval set
  #   i.intersect?(0...1)         # -> true
  #   i.intersect?(0...2)         # -> true
  #   i.intersect?(1...2)         # -> false ; the start of a range is inclusive but the end exclusive
  #
  #   # The same applies for interval sets
  #   i.intersect?(IntervalSet[0...1])         # -> true
  #   i.intersect?(IntervalSet[0...1, 2...3])  # -> true
  #   i.intersect?(IntervalSet[2...3])         # -> false
  #
  # @param other [Range | IntervalSet] the other object.
  def intersect?(other)
    case other
      when Range
        intersect_range?(other)
      when IntervalSet
        intersect_interval_set?(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  # Counts the number of ranges contained by this IntervalSet.
  #
  #   i = IntervalSet[]           # -> []
  #   i.count                     # -> 0
  #   i << (0...1)                # -> [0...1]
  #   i.count                     # -> 1
  #   i << (2...3)                # -> [0...1, 2...3]
  #   i.count                     # -> 2
  #   i << (1...2)                # -> [0...3]
  #   i.count                     # -> 1
  #
  # @return [Fixnum] the number of ranges.
  def count
    @range_map.count
  end

  # Adds the other object's elements to this IntervalSet.
  # The result is stored in this IntervalSet.
  #
  #   IntervalSet.new.add(0...1)  # -> [0...1]
  #   IntervalSet.new << (0...1)  # -> [0...1]
  #
  #   i = IntervalSet.new         # -> []
  #   i << (0...1)                # -> [0...1]
  #   i << (2...3)                # -> [0...1, 2...3]
  #   i << (1...2)                # -> [0...3]
  #   i << (-1...4)               # -> [-1...4]
  #
  # @param other [Range, IntervalSet] the other object.
  # @return [IntervalSet] self.
  def add(other)
    case other
      when Range
        add_range(other)
      when IntervalSet
        add_interval_set(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  alias_method :<<, :add
  alias_method :union!, :add

  # Removes the other object's elements from this IntervalSet.
  # The result is stored in this IntervalSet.
  #
  #   i = IntervalSet[0...10]     # -> [0...10]
  #   i.remove(0...2)             # -> [8...10]
  #   i >> (2...8)                # -> [0...2, 8...10]
  #
  # @param other [Range, IntervalSet] the other object.
  # @return [IntervalSet] self.
  def remove(other)
    case other
      when Range
        remove_range(other)
      when IntervalSet
        remove_interval_set(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  alias_method :>>, :remove
  alias_method :difference!, :remove

  # Intersects the other object's elements with this IntervalSet.
  # The result is stored in this IntervalSet.
  #
  #   i = IntervalSet[0...2, 3...5].intersect(1...5) # -> [1...2, 3...5]
  #   i                                              # -> [1...2, 3...5]
  #
  # @param other [Range, IntervalSet] the other object.
  # @return [IntervalSet] self.
  def intersect(other)
    case other
      when Range
        intersect_range(other)
      when IntervalSet
        intersect_interval_set(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  alias_method :intersection!, :intersect

  # Intersects the other object's elements with this IntervalSet.
  # The result is stored in a new IntervalSet.
  #
  #   IntervalSet[0...2, 3...5] & IntervalSet[1...4, 5...6] # -> [1...2, 3...4]
  #
  # @param other [Range, IntervalSet] the other object.
  # @return [IntervalSet] a new IntervalSet containing the intersection.
  def intersection(other)
    case other
      when Range
        intersection_range(other)
      when IntervalSet
        intersection_interval_set(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  alias_method :&, :intersection

  # Joins the other object's elements with this IntervalSet.
  # The result is stored in a new IntervalSet.
  #
  #   IntervalSet[0...1, 2...3] | IntervalSet[1...2, 4...5] # -> [0...3, 4...5]
  #
  # Note that using +add+ or +union!+ is more efficient than
  # <code>+=</code> or <code>|=</code>.
  #
  # @param other [Range, IntervalSet] the other object.
  # @return [IntervalSet] a new IntervalSet containing the union.
  def union(other)
    case other
      when Range
        union_range(other)
      when IntervalSet
        union_interval_set(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  alias_method :|, :union
  alias_method :+, :union

  # Subtracts the other object's elements from this IntervalSet.
  # The result is stored in a new IntervalSet.
  #
  #   IntervalSet[0...2, 3...5] - IntervalSet[1...4, 5...6] # -> [0...1, 4...5]
  #
  # Note that using +remove+ or +difference!+ is more efficient
  # than <code>-=</code>.
  #
  # @param other [Range, IntervalSet] the other object.
  # @return [IntervalSet] a new IntervalSet containing the difference.
  def difference(other)
    case other
      when Range
        difference_range(other)
      when IntervalSet
        difference_interval_set(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  alias_method :-, :difference

  # Calculates a new IntervalSet which only contains elements exclusively from
  # either this or the given object.
  #
  # This operation is equivalent to <code>(self | other) - (self & other)</code>
  #
  #   IntervalSet[0...1] ^ IntervalSet[1...2]               # -> [0...2]
  #   IntervalSet[0...2, 4...6] ^ IntervalSet[1...5, 7...8] # -> [0...1, 2...4, 5...6, 7...8]
  #   IntervalSet[0...1] ^ IntervalSet[0...1]               # -> []
  #
  # @param other [Range, IntervalSet]
  # @return [IntervalSet] a new IntervalSet containing the exclusive set.
  def xor(other)
    clone.xor!(other)
  end

  alias_method :^, :xor

  # Calculates the set which contains elements exclusively from
  # either this or the given object. The result of this operation
  # is stored in this set.
  #
  # The resulting set is equivalent to <code>(self | other) - (self & other)</code>
  #
  #   IntervalSet[0...1].xor!(IntervalSet[1...2])               # -> [0...2]
  #   IntervalSet[0...2, 4...6].xor!(IntervalSet[1...5, 7...8]) # -> [0...1, 2...4, 5...6, 7...8]
  #   IntervalSet[0...1].xor!(IntervalSet[0...1])               # -> []
  #
  # @param other [Range, IntervalSet]
  # @return [IntervalSet] a new IntervalSet containing the exclusive set.
  def xor!(other)
    intersection = self & other

    add(other).remove(intersection)
  end

  # Convolves the other object's elements with this IntervalSet.
  # The result is stored in this IntervalSet.
  #
  # The result will contain all elements which can be obtained by adding
  # any pair of elements from both sets. A ∗ B = { a + b | a ∈ A ∧ b ∈ B }
  #
  #   # Convolve with a range (effectively buffers the set)
  #   IntervalSet[0...4].convolve!(-1...2) # -> [-1...6]
  #
  #   # Convolving with empty or reversed ranges result in an empty set.
  #   IntervalSet[0...4].convolve!(0...0)  # -> []
  #   IntervalSet[0...4].convolve!(1...0)  # -> []
  #
  #   # Convolve with a interval set
  #   IntervalSet[0...1, 10...12].convolve!(IntervalSet[-2...1, 1...2]) # -> [-2...3, 8...14]
  #
  # @param other [Range | IntervalSet] the other object.
  # @return [IntervalSet] self
  def convolve!(other)
    case other
      when Range
        convolve_range!(other)
      when IntervalSet
        convolve_interval_set!(other)
      else
        IntervalSet.unexpected_object(other)
    end
  end

  # Convolves the other object's elements with this IntervalSet.
  # The result is stored in a new IntervalSet.
  #
  # The result will contain all elements which can be obtained by adding
  # any pair of elements from both sets. A ∗ B = { a + b | a ∈ A ∧ b ∈ B }
  #
  #   # Convolve with a range (effectively buffers the set)
  #   IntervalSet[0...4] * (-1...2) # -> [-1...6]
  #
  #   # Convolving with empty or reversed ranges result in an empty set.
  #   IntervalSet[0...4] * (0...0)  # -> []
  #   IntervalSet[0...4] * (1...0)  # -> []
  #
  #   # Convolve with a interval set
  #   IntervalSet[0...1, 10...12] * IntervalSet[-2...1, 1...2]  # -> [-2...3, 8...14]
  #
  # @param other [Range | IntervalSet] the other object.
  # @return [IntervalSet] a new IntervalSet containing the convolution.
  def convolve(other)
    clone.convolve!(other)
  end

  alias_method :*, :convolve

  # Shifts this IntervalSet by the given amount.
  # The result is stored in this IntervalSet.
  #
  #   IntervalSet[0...1].shift(1)   # -> [1...2]
  #
  # Note that +shift(0)+ will not be optimized since IntervalSet does
  # not assume numbers as element type.
  #
  # @param amount [Object]
  # @return [IntervalSet] self.
  def shift!(amount)
    ranges = map {|range| range.first + amount...range.last + amount}
    clear
    ranges.each {|range| put(range)}
    update_bounds

    self
  end

  # Shifts this IntervalSet by the given amount.
  # The result is stored in a new IntervalSet.
  #
  #   IntervalSet[0...1].shift!(1)  # -> [1...2]
  #
  # Note that +shift!(0)+ will not be optimized since IntervalSet does
  # not assume numbers as element type.
  #
  # @param amount [Object]
  # @return [IntervalSet] a new IntervalSet shifted by +amount+.
  def shift(amount)
    clone.shift!(amount)
  end

  # Buffers this IntervalSet by adding a left and right margin to each range.
  # The result is stored in this IntervalSet.
  #
  #   IntervalSet[1...2].buffer!(1, 2) # -> [0...4]
  #
  #   # negative values will shrink the ranges
  #   IntervalSet[0...4].buffer!(-1, -2) # -> [1...2]
  #   IntervalSet[1...2].buffer!(-0.5, -0.5) # -> []
  #
  # @param left [Object] margin added to the left side of each range.
  # @param right [Object] margin added to the right side of each range.
  # @return [IntervalSet] self.
  def buffer!(left, right)
    ranges = map do |range|
      range.first - left...range.last + right
    end.select do |range|
      range.first < range.last
    end

    clear
    ranges.each {|r| add_range(r)}

    self
  end

  # Buffers this IntervalSet by adding a left and right margin to each range.
  # The result is stored in a new IntervalSet.
  #
  #   IntervalSet[1...2].buffer(1, 2)       # -> [0...4]
  #
  #   # negative values will shrink the ranges
  #   IntervalSet[0...4].buffer(-1, -2)     # -> [1...2]
  #   IntervalSet[1...2].buffer(-0.5, -0.5) # -> []
  #
  # @param left [Object] margin added to the left side of each range.
  # @param right [Object] margin added to the right side of each range.
  # @return [IntervalSet] a new IntervalSet containing the buffered ranges.
  def buffer(left, right)
    clone.buffer!(left, right)
  end

  # Removes all elements from this IntervalSet.
  # @return [IntervalSet] self.
  def clear
    @range_map.clear
    @min = nil
    @max = nil

    self
  end

  # Iterates over all ranges of this set in ascending order.
  # @yield all ranges.
  # @yieldparam [Range] range.
  # @return [void]
  def each
    @range_map.each_node {|node| yield node.value}
  end

  # Returns a new IntervalSet instance containing all ranges of this IntervalSet.
  # @return [IntervalSet] the clone.
  def clone
    IntervalSet.new.copy(self)
  end

  # Replaces the content of this IntervalSet by the content of the given IntervalSet.
  # @param interval_set [IntervalSet] the other IntervalSet to be copied
  # @return [IntervalSet] self.
  def copy(interval_set)
    clear
    interval_set.each {|range| put(range)}
    @min = interval_set.min
    @max = interval_set.max

    self
  end

  # Returns a String representation of this IntervalSet.
  #
  #   IntervalSet[].to_s             # -> "[]"
  #   IntervalSet[0...1].to_s        # -> "[0...1]"
  #   IntervalSet[0...1, 2...3].to_s # -> "[0...1, 2...3]"
  #
  # @return [String] the String representation.
  def to_s
    string_io = StringIO.new

    last_index = count - 1

    string_io << '['
    each_with_index do |range, i|
      string_io << range
      string_io << ', ' if i < last_index
    end
    string_io << ']'

    string_io.string
  end

  alias_method :inspect, :to_s

  protected

  def range_map
    @range_map
  end

  def put(range)
    @range_map.put(range.first, IntervalSet.normalize_range(range))
  end

  def put_and_update_bounds(range)
    put(range)

    if @min.nil? && @max.nil?
      @min = range.first
      @max = range.last
    else
      @min = [range.first, @min].min
      @max = [range.last, @max].max
    end
  end

  def superset_range?(range)
    return true if IntervalSet.range_empty?(range)
    return false if empty? || !bounds_intersected_by?(range)

    # left.min <= range.first
    left_entry = @range_map.floor_entry(range.first)

    # left.max >= range.last
    !left_entry.nil? && left_entry.value.last >= range.last
  end

  def superset_interval_set?(interval_set)
    return true if interval_set == self || interval_set.empty?
    return false if empty? || !interval_set.bounds_intersected_by?(bounds)

    interval_set.all? {|range| superset_range?(range)}
  end

  def subset_range?(range)
    return true if empty?
    return false if IntervalSet.range_empty?(range)

    empty? || (range.first <= min && range.last >= max)
  end

  def intersect_range?(range)
    return false unless bounds_intersected_by?(range)

    # left.min < range.last
    left_entry = @range_map.lower_entry(range.last)

    # left.max > range.first
    !left_entry.nil? && left_entry.value.last > range.first
  end

  def intersect_interval_set?(interval_set)
    return false if empty? || !bounds_intersected_by?(interval_set.bounds)

    sub_set(interval_set.bounds).any? {|range| intersect_range?(range)}
  end

  def eql_range?(range)
    return true if empty? && IntervalSet.range_empty?(range)

    count == 1 && bounds == range
  end

  def sub_set(range)
    # left.min < range.first
    left_entry = @range_map.lower_entry(range.first)

    # left.max > range.first
    include_left = !left_entry.nil? && left_entry.value.last > range.first

    bound_min = include_left ? left_entry.value.first : range.first
    sub_map = @range_map.sub_map(bound_min, range.last)

    IntervalSet.new(sub_map)
  end

  def head_set(value)
    head_map = @range_map.head_map(value)

    IntervalSet.new(head_map)
  end

  def tail_set(value)
    # left.min < value
    left_entry = @range_map.lower_entry(value)

    # left.max > value
    include_left = !left_entry.nil? && left_entry.value.last > value

    bound_min = include_left ? left_entry.value.first : value
    tail_map = @range_map.tail_map(bound_min)

    IntervalSet.new(tail_map)
  end

  def add_range(range)
    # ignore empty or reversed ranges
    return self if IntervalSet.range_empty?(range)

    # short cut
    unless bounds_intersected_or_touched_by?(range)
      put_and_update_bounds(range)
      return self
    end

    # short cut
    if subset_range?(range)
      clear
      put_and_update_bounds(range)
      return self
    end

    # range.first <= core.min <= range.last
    core = @range_map.sub_map(range.first, true, range.last, true)

    # short cut if range already included
    if !core.empty? && core.first_entry == core.last_entry
      core_range = core.first_entry.value

      return self if core_range.first == range.first && core_range.last == range.last
    end

    # left.min < range.first
    left_entry = @range_map.lower_entry(range.first)
    # right.min <= range.last
    right_entry = core.empty? ? left_entry : core.last_entry

    # determine boundaries

    # left.max >= range.first
    include_left = !left_entry.nil? && left_entry.value.last >= range.first
    # right.max > range.last
    include_right = !right_entry.nil? && right_entry.value.last > range.last

    left_boundary = include_left ? left_entry.key : range.first
    right_boundary = include_right ? right_entry.value.last : range.last

    @range_map.remove(left_boundary) if include_left

    core.keys.each {|key| @range_map.remove(key)}

    # add range

    if !include_left && !include_right
      put_and_update_bounds(range)
    else
      put_and_update_bounds(left_boundary...right_boundary)
    end

    self
  end

  def add_interval_set(interval_set)
    return self if interval_set == self || interval_set.empty?

    interval_set.each {|range| add_range(range)}

    self
  end

  def remove_range(range)
    return self unless bounds_intersected_by?(range)

    # range.first <= core.min <= range.last
    core = @range_map.sub_map(range.first, true, range.last, false)

    # left.min < range.first
    left_entry = @range_map.lower_entry(range.first)
    # right.min < range.last
    right_entry = core.empty? ? left_entry : core.last_entry

    # left.max > range.to
    include_left = !left_entry.nil? && left_entry.value.last > range.first
    # right.max > range.last
    include_right = !right_entry.nil? && right_entry.value.last > range.last

    core.keys.each {|key| @range_map.remove(key)}

    # right first since right might be same as left
    put(range.last...right_entry.value.last) if include_right
    put(left_entry.key...range.first) if include_left
    update_bounds

    self
  end

  def remove_interval_set(interval_set)
    if interval_set == self
      clear
    else
      interval_set.each {|range| remove_range(range)}
    end

    self
  end

  def intersect_range(range)
    unless bounds_intersected_by?(range)
      clear
      return self
    end

    return self if subset_range?(range)

    # left_map.min < range.first
    left_map = @range_map.head_map(range.first, false)
    # right_map.min >= range.last
    right_map = @range_map.tail_map(range.last, true)

    # left.min < range.first
    left_entry = left_map.last_entry
    # right.min < range.last
    right_entry = @range_map.lower_entry(range.last)

    # left.max > range.first
    include_left = !left_entry.nil? && left_entry.value.last > range.first
    # right.max > right.max
    include_right = !right_entry.nil? && right_entry.value.last > range.last

    left_map.keys.each {|key| @range_map.remove(key)}
    right_map.keys.each {|key| @range_map.remove(key)}

    put(range.first...[left_entry.value.last, range.last].min) if include_left
    put([right_entry.key, range.first].max...range.last) if include_right
    update_bounds

    self
  end

  def intersect_interval_set(interval_set)
    return self if interval_set == self

    if interval_set.empty? || !bounds_intersected_by?(interval_set.bounds)
      clear
      return self
    end

    intersection = interval_set.sub_set(bounds).map do |range|
      IntervalSet.new.tap do |interval_set_item|
        interval_set_item.add_interval_set(sub_set(range))
        interval_set_item.intersect_range(range)
      end
    end.reduce do |acc, interval_set_item|
      acc.add_interval_set(interval_set_item); acc
    end

    @range_map = intersection.range_map
    @min = intersection.min
    @max = intersection.max

    self
  end

  def union_range(range)
    new_interval_set = IntervalSet.new
    new_interval_set.add_interval_set(self) unless subset_range?(range)
    new_interval_set.add_range(range)
  end

  def union_interval_set(interval_set)
    new_interval_set = clone
    new_interval_set.add_interval_set(interval_set)
  end

  def difference_range(range)
    new_interval_set = IntervalSet.new

    return new_interval_set if subset_range?(range)
    return new_interval_set.copy(self) unless bounds_intersected_by?(range)

    unless IntervalSet.range_empty?(range)
      new_interval_set.add_interval_set(head_set(range.first))
      new_interval_set.add_interval_set(tail_set(range.last))
      new_interval_set.remove_range(range)
    end
  end

  def difference_interval_set(interval_set)
    new_interval_set = IntervalSet.new

    return new_interval_set if interval_set == self || empty?

    new_interval_set.copy(self)
    new_interval_set.remove_interval_set(interval_set) if !interval_set.empty? && bounds_intersected_by?(interval_set.bounds)
    new_interval_set
  end

  def intersection_range(range)
    new_interval_set = IntervalSet.new

    return new_interval_set unless bounds_intersected_by?(range)
    return new_interval_set.copy(self) if subset_range?(range)

    new_interval_set.add(sub_set(range))
    new_interval_set.intersect_range(range)
  end

  def intersection_interval_set(interval_set)
    new_interval_set = IntervalSet.new

    return new_interval_set if interval_set.empty? || !bounds_intersected_by?(interval_set.bounds)

    new_interval_set.add_interval_set(self)
    new_interval_set.intersect_interval_set(interval_set.sub_set(bounds))
  end

  def convolve_range!(range)
    if IntervalSet.range_empty?(range)
      clear
    else
      buffer!(-range.first, range.last)
    end
  end

  def convolve_interval_set!(interval_set)
    interval_sets = interval_set.map {|range| clone.convolve_range!(range)}
    clear
    interval_sets.each {|rs| add_interval_set(rs)}

    self
  end

  private

  def update_bounds
    if empty?
      @min = nil
      @max = nil
    else
      @min = @range_map.first_entry.value.first
      @max = @range_map.last_entry.value.last
    end
  end

  def self.range_empty?(range)
    range.first >= range.last
  end

  def self.normalize_range(range)
    range.exclude_end? ? range : range.first...range.last
  end

  def self.unexpected_object(object)
    raise ArgumentError.new("unexpected object #{object}")
  end

end
