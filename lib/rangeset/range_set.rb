require_relative 'version'
require 'treemap-fork'

# RangeSet implements a set of sorted non-overlapping ranges.
# A range's start is always interpreted as inclusive while the end is exclusive
class RangeSet
  include Enumerable

  # Builds a new RangeSet from the supplied ranges. Overlapping ranges will be merged.
  #   RangeSet[]                # -> []
  #   RangeSet[0...1]           # -> [0...1]
  #   RangeSet[0...1, 2...3]    # -> [0...1, 2...3]
  #   RangeSet[0...1, 1...2]    # -> [0...2]
  #
  #   array = [0...1, 2...3]
  #   RangeSet[*array]          # -> [0...1, 2...3]
  #
  # @param ranges [Range[]] a list of ranges to be added to the new Rangeset
  # @return [RangeSet] a new RangeSet containing the supplied ranges.
  def self.[](*ranges)
    RangeSet.new.tap do |range_set|
      ranges.each {|range| range_set << range}
    end
  end

  # Returns an empty instance of RangeSet.
  # @param range_map [TreeMap] a TreeMap of ranges. For internal use only.
  def initialize(range_map = TreeMap.new)
    unless range_map.instance_of?(TreeMap) || range_map.instance_of?(TreeMap::BoundedMap)
      raise ArgumentError.new("invalid range_map #{range_map}")
    end

    @range_map = range_map

    update_bounds
  end

  # Returns +true+ if this RangeSet contains no ranges.
  def empty?
    @range_map.empty?
  end

  # Returns the lower bound of this RangeSet.
  #
  #   RangeSet[0...1, 2...3].min  # -> 0
  #   RangeSet[].min              # -> nil
  #
  # @return the lower bound or +nil+ if empty.
  def min
    @min
  end

  # Returns the upper bound of this RangeSet.
  #
  #   RangeSet[0...1, 2...3].max  # -> 3
  #   RangeSet[].max              # -> nil
  #
  # @return the upper bound or +nil+ if empty.
  def max
    @max
  end

  # Returns the bounds of this RangeSet.
  #
  #   RangeSet[0...1, 2...3].bounds # -> 0...3
  #   RangeSet[].bounds             # -> nil
  #
  # @return [Range] a range from lower to upper bound.
  def bounds
    empty? ? nil : min...max
  end

  # Returns +true+ if two RangeSets are equal.
  #
  #   RangeSet[0...1] == RangeSet[0...1]  # -> true
  #   RangeSet[0...1] == RangeSet[1...2]  # -> false
  #
  # @param other [RangeSet] the other RangeSet.
  def eql?(other)
    return false if count != other.count
    return false if bounds != other.bounds

    lhs_iter = enum_for
    rhs_iter = other.enum_for

    count.times.all? {lhs_iter.next == rhs_iter.next}
  end

  alias_method :==, :eql?

  # Returns +true+ if the other object represents a equal
  # set of ranges as this RangeSet.
  #
  #   RangeSet[1...2].eql_set?(1...2)           # -> true
  #   RangeSet[1...2].eql_set?(RangeSet[1...2]) # -> true
  #
  # @param other [Range | RangeSet] the other object.
  def eql_set?(other)
    case other
      when Range
        eql_range?(other)
      when RangeSet
        eql?(other)
      else
        RangeSet.unexpected_object(other)
    end
  end

  # Returns +true+ if this RangeSet contains the given element.
  #
  #   r = RangeSet[0...1]         # -> [0...1]
  #
  #   r.include?(0)               # -> true
  #   r.include?(0.5)             # -> true
  #   r.include?(1)               # -> false ; a range's end is exclusive
  #
  # @param element [Object]
  def include?(element)
    floor_entry = @range_map.floor_entry(element)

    !floor_entry.nil? && floor_entry.value.last > element
  end

  alias_method :===, :include?

  # Returns +true+ if this RangeSet includes all elements
  # of the other object.
  #
  #   RangeSet[0...1] >= RangeSet[0...1]        # -> true
  #   RangeSet[0...2] >= RangeSet[0...1]        # -> true
  #   RangeSet[0...1] >= RangeSet[0...1, 2...3] # -> false
  #   RangeSet[0...3] >= RangeSet[0...1, 2...3] # -> true
  #
  #   # You can also supply ranges
  #   RangeSet[0...2].superset?(0...1)  # -> true
  #
  # @param other [Range | RangeSet] the other object.
  def superset?(other)
    case other
      when Range
        superset_range?(other)
      when RangeSet
        superset_range_set?(other)
      else
        RangeSet.unexpected_object(other)
    end
  end

  alias_method :>=, :superset?

  # Returns +true+ if all elements of this RangeSet are
  # included by the other object.
  #
  #   RangeSet[0...1] <= RangeSet[0...1]        # -> true
  #   RangeSet[0...1] <= RangeSet[0...1, 2...3] # -> true
  #   RangeSet[0...1, 2...3] <= RangeSet[0...1] # -> false
  #   RangeSet[0...1, 2...3] <= RangeSet[0...3] # -> true
  #
  #   # You can also supply ranges
  #   RangeSet[0...1, 2...3].subset?(0...3)    # -> true
  #
  # @param other [Range | RangeSet] the other object.
  def subset?(other)
    case other
      when Range
        subset_range?(other)
      when RangeSet
        other.superset_range_set?(self)
      else
        RangeSet.unexpected_object(other)
    end
  end

  alias_method :<=, :subset?

  # Returns +true+ if this RangeSet is a proper superset of the other.
  #
  #   RangeSet[0...2] > RangeSet[0...1] # -> true
  #   RangeSet[0...2] > RangeSet[0...2] # -> false
  #   RangeSet[0...2] > RangeSet[1...3] # -> false
  #
  #   # Compare to ranges
  #   RangeSet[0...3].superset?(1...2)  # -> true
  #
  # @param other [Range | RangeSet] the other object.
  def proper_superset?(other)
    !eql_set?(other) && superset?(other)
  end

  alias_method :>, :proper_superset?

  # Return +true+ if this RangeSet is a proper subset of the other.
  #
  #   RangeSet[0...1] < RangeSet[0...2] # -> true
  #   RangeSet[1...3] < RangeSet[0...2] # -> false
  #   RangeSet[1...3] < RangeSet[0...2] # -> false
  #
  #   # Compare to ranges
  #   RangeSet[1...2].subset?(0...3)    # -> false
  #
  # @param other [Range | RangeSet] the other object.
  def proper_subset?(other)
    !eql_set?(other) && subset?(other)
  end

  alias_method :<, :proper_subset?

  # Returns +true+ if the given range has common elements with the
  # bounding range of this RangeSet.
  #
  #   RangeSet[1...2].bounds_intersected_by?(2...3)         # -> false
  #   RangeSet[1...2, 5...6].bounds_intersected_by?(3...4)  # -> true
  #
  # @param range [Range]
  def bounds_intersected_by?(range)
    return false if RangeSet.range_empty?(range)

    !empty? && range.first < max && range.last > min
  end

  # Returns +true+ if the given range has common elements with the
  # bounding range or the bounds of this RangeSet.
  #
  #   RangeSet[1...2].bounds_intersected_or_touched_by?(2...3)        # -> true
  #   RangeSet[1...2].bounds_intersected_or_touched_by?(3...4)        # -> false
  #   RangeSet[1...2, 5...6].bounds_intersected_or_touched_by?(3...4) # -> true
  #
  # @param range [Range]
  def bounds_intersected_or_touched_by?(range)
    return false if RangeSet.range_empty?(range)

    !empty? && range.first <= max && range.last >= min
  end

  # Returns +true+ if the given object has any common elements with
  # this RangeSet.
  #
  #   r = RangeSet[0...1]         # -> [0...1]
  #
  #   # For a single element intersect? behaves exactly like include?
  #   r.intersect?(0)             # -> true
  #   r.intersect?(0.5)           # -> true
  #   r.intersect?(1)             # -> false
  #
  #   # Ranges only need a single common element with the range set
  #   r.intersect?(0...1)         # -> true
  #   r.intersect?(0...2)         # -> true
  #   r.intersect?(1...2)         # -> false ; the start of a range is inclusive but the end exclusive
  #
  #   # The same applies for range sets
  #   r.intersect?(RangeSet[0...1])         # -> true
  #   r.intersect?(RangeSet[0...1, 2...3])  # -> true
  #   r.intersect?(RangeSet[2...3])         # -> false
  #
  # @param other [Range | RangeSet | #<=>] the other object.
  def intersect?(other)
    case other
      when Range
        intersect_range?(other)
      when RangeSet
        intersect_range_set?(other)
      else
        include?(other)
    end
  end

  # Counts the number of ranges contained by this RangeSet.
  #
  #   r = RangeSet[]              # -> []
  #   r.count                     # -> 0
  #   r << (0...1)                # -> [0...1]
  #   r.count                     # -> 1
  #   r << (2...3)                # -> [0...1, 2...3]
  #   r.count                     # -> 2
  #   r << (1...2)                # -> [0...3]
  #   r.count                     # -> 1
  #
  # @return [Integer] the number of ranges.
  def count
    @range_map.count
  end

  # Adds the other object's elements to this RangeSet.
  # The result is stored in this RangeSet.
  #
  #   RangeSet.new.add(0...1)     # -> [0...1]
  #   RangeSet.new << (0...1)     # -> [0...1]
  #
  #   r = RangeSet.new            # -> []
  #   r << (0...1)                # -> [0...1]
  #   r << (2...3)                # -> [0...1, 2...3]
  #   r << (1...2)                # -> [0...3]
  #   r << (-1...4)               # -> [-1...4]
  #
  # @param other [Range, RangeSet] the other object.
  # @return [RangeSet] self.
  def add(other)
    case other
      when Range
        add_range(other)
      when RangeSet
        add_range_set(other)
      else
        RangeSet.unexpected_object(other)
    end
  end

  alias_method :<<, :add
  alias_method :union!, :add

  # Removes the other object's elements from this RangeSet.
  # The result is stored in this RangeSet.
  #
  #   r = RangeSet[0...10]        # -> [0...10]
  #   r.remove(0...2)             # -> [8...10]
  #   r >> (2...8)                # -> [0...2, 8...10]
  #
  # @param other [Range, RangeSet] the other object.
  # @return [RangeSet] self.
  def remove(other)
    case other
      when Range
        remove_range(other)
      when RangeSet
        remove_range_set(other)
      else
        RangeSet.unexpected_object(other)
    end
  end

  alias_method :>>, :remove
  alias_method :difference!, :remove

  # Intersects the other object's elements with this RangeSet.
  # The result is stored in this RangeSet.
  #
  #   r = RangeSet[0...2, 3...5].intersect(1...5) # -> [1...2, 3...5]
  #   r                                           # -> [1...2, 3...5]
  #
  # @param other [Range, RangeSet] the other object.
  # @return [RangeSet] self.
  def intersect(other)
    case other
      when Range
        intersect_range(other)
      when RangeSet
        intersect_range_set(other)
      else
        RangeSet.unexpected_object(other)
    end
  end

  alias_method :intersection!, :intersect

  # Intersects the other object's elements with this RangeSet.
  # The result is stored in a new RangeSet.
  #
  #   RangeSet[0...2, 3...5] & RangeSet[1...4, 5...6] # -> [1...2, 3...4]
  #
  # @param other [Range, RangeSet] the other object.
  # @return [RangeSet] a new RangeSet containing the intersection.
  def intersection(other)
    case other
      when Range
        intersection_range(other)
      when RangeSet
        intersection_range_set(other)
      else
        RangeSet.unexpected_object(other)
    end
  end

  alias_method :&, :intersection

  # Joins the other object's elements with this RangeSet.
  # The result is stored in a new RangeSet.
  #
  #   RangeSet[0...1, 2...3] | RangeSet[1...2, 4...5] # -> [0...3, 4...5]
  #
  # Note that using +add+ or +union!+ is more efficient than
  # <code>+=</code> or <code>|=</code>.
  #
  # @param other [Range, RangeSet] the other object.
  # @return [RangeSet] a new RangeSet containing the union.
  def union(other)
    case other
      when Range
        union_range(other)
      when RangeSet
        union_range_set(other)
      else
        RangeSet.unexpected_object(other)
    end
  end

  alias_method :|, :union
  alias_method :+, :union

  # Subtracts the other object's elements from this RangeSet.
  # The result is stored in a new RangeSet.
  #
  #   RangeSet[0...2, 3...5] - RangeSet[1...4, 5...6] # -> [0...1, 4...5]
  #
  # Note that using +remove+ or +difference!+ is more efficient
  # than <code>-=</code>.
  #
  # @param other [Range, RangeSet] the other object.
  # @return [RangeSet] a new RangeSet containing the difference.
  def difference(other)
    case other
      when Range
        difference_range(other)
      when RangeSet
        difference_range_set(other)
      else
        RangeSet.unexpected_object(other)
    end
  end

  alias_method :-, :difference

  # Convolves the other object's elements with this RangeSet.
  # The result is stored in this RangeSet.
  #
  # The result will contain all elements which can be obtained by adding
  # any pair of elements from both sets. A ∗ B = { a + b | a ∈ A ∧ b ∈ B }
  #
  #   # Convolve with a singleton (effectively shifts the set)
  #   RangeSet[0...1].convolve!(1)      # -> [1...2]
  #
  #   # Convolve with a range (effectively buffers the set)
  #   RangeSet[0...4].convolve!(-1...2) # -> [-1...6]
  #
  #   # Convolving with empty or reversed ranges result in an empty set.
  #   RangeSet[0...4].convolve!(0...0)  # -> []
  #   RangeSet[0...4].convolve!(1...0)  # -> []
  #
  #   # Convolve with a range set
  #   RangeSet[0...1, 10...12].convolve!(RangeSet[-2...1, 1...2]) # -> [-2...3, 8...14]
  #
  # @param other [Range | RangeSet | Object] the other object.
  # @return [RangeSet] self
  def convolve!(other)
    case other
      when Range
        convolve_range!(other)
      when RangeSet
        convolve_range_set!(other)
      else
        convolve_element!(other)
    end
  end

  # Convolves the other object's elements with this RangeSet.
  # The result is stored in a new RangeSet.
  #
  # The result will contain all elements which can be obtained by adding
  # any pair of elements from both sets. A ∗ B = { a + b | a ∈ A ∧ b ∈ B }
  #   # Convolve with a singleton (effectively shifts the set)
  #   RangeSet[0...1] * 1         # -> [1...2]
  #
  #   # Convolve with a range (effectively buffers the set)
  #   RangeSet[0...4] * (-1...2)  # -> [-1...6]
  #
  #   # Convolving with empty or reversed ranges result in an empty set.
  #   RangeSet[0...4] * (0...0)   # -> []
  #   RangeSet[0...4] * (1...0)   # -> []
  #
  #   # Convolve with a range set
  #   RangeSet[0...1, 10...12] * RangeSet[-2...1, 1...2]  # -> [-2...3, 8...14]
  #
  # @param other [Range | RangeSet | Object] the other object.
  # @return [RangeSet] a new RangeSet containing the convolution.
  def convolve(other)
    clone.convolve!(other)
  end

  alias_method :*, :convolve

  # Shifts this RangeSet by the given amount.
  # The result is stored in this RangeSet.
  #
  #   RangeSet[0...1].shift(1)    # -> [1...2]
  #
  # Note that +shift(0)+ will not be optimized since RangeSet does
  # not assume numbers as element type.
  #
  # @param amount [Object]
  # @return [RangeSet] self.
  def shift!(amount)
    convolve_element!(amount)
  end

  # Shifts this RangeSet by the given amount.
  # The result is stored in a new RangeSet.
  #
  #   RangeSet[0...1].shift!(1)   # -> [1...2]
  #
  # Note that +shift!(0)+ will not be optimized since RangeSet does
  # not assume numbers as element type.
  #
  # @param amount [Object]
  # @return [RangeSet] a new RangeSet shifted by +amount+.
  def shift(amount)
    clone.shift!(amount)
  end

  # Buffers this RangeSet by adding a left and right margin to each range.
  # The result is stored in this RangeSet.
  #
  #   RangeSet[1...2].buffer!(1, 2) # -> [0...4]
  #
  #   # negative values will shrink the ranges
  #   RangeSet[0...4].buffer!(-1, -2) # -> [1...2]
  #   RangeSet[1...2].buffer!(-0.5, -0.5) # -> []
  #
  # @param left [Object] margin added to the left side of each range.
  # @param right [Object] margin added to the right side of each range.
  # @return [RangeSet] self.
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

  # Buffers this RangeSet by adding a left and right margin to each range.
  # The result is stored in a new RangeSet.
  #
  #   RangeSet[1...2].buffer(1, 2)        # -> [0...4]
  #
  #   # negative values will shrink the ranges
  #   RangeSet[0...4].buffer(-1, -2)      # -> [1...2]
  #   RangeSet[1...2].buffer(-0.5, -0.5)  # -> []
  #
  # @param left [Object] margin added to the left side of each range.
  # @param right [Object] margin added to the right side of each range.
  # @return [RangeSet] a new RangeSet containing the buffered ranges.
  def buffer(left, right)
    clone.buffer!(left, right)
  end

  # Removes all elements from this RangeSet.
  # @return [RangeSet] self.
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

  # Returns a new RangeSet instance containing all ranges of this RangeSet.
  # @return [RangeSet] the clone.
  def clone
    RangeSet.new.copy(self)
  end

  # Replaces the content of this RangeSet by the content of the given RangeSet.
  # @param range_set [RangeSet] the other RangeSet to be copied
  # @return [RangeSet] self.
  def copy(range_set)
    clear
    range_set.each {|range| put(range)}
    @min = range_set.min
    @max = range_set.max

    self
  end

  # Returns a String representation of this RangeSet.
  #
  #   RangeSet[].to_s             # -> "[]"
  #   RangeSet[0...1].to_s        # -> "[0...1]"
  #   RangeSet[0...1, 2...3].to_s # -> "[0...1, 2...3]"
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
    @range_map.put(range.first, RangeSet.normalize_range(range))
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
    return true if RangeSet.range_empty?(range)
    return false if empty? || !bounds_intersected_by?(range)

    # left.min <= range.first
    left_entry = @range_map.floor_entry(range.first)

    # left.max >= range.last
    !left_entry.nil? && left_entry.value.last >= range.last
  end

  def superset_range_set?(range_set)
    return true if range_set == self || range_set.empty?
    return false if empty? || !range_set.bounds_intersected_by?(bounds)

    range_set.all? {|range| superset_range?(range)}
  end

  def subset_range?(range)
    return true if empty?
    return false if RangeSet.range_empty?(range)

    empty? || (range.first <= min && range.last >= max)
  end

  def intersect_range?(range)
    return false unless bounds_intersected_by?(range)

    # left.min < range.last
    left_entry = @range_map.lower_entry(range.last)

    # left.max > range.first
    !left_entry.nil? && left_entry.value.last > range.first
  end

  def intersect_range_set?(range_set)
    return false if empty? || !bounds_intersected_by?(range_set.bounds)

    sub_set(range_set.bounds).any? {|range| intersect_range?(range)}
  end

  def eql_range?(range)
    return true if empty? && RangeSet.range_empty?(range)

    count == 1 && bounds == range
  end

  def sub_set(range)
    # left.min < range.first
    left_entry = @range_map.lower_entry(range.first)

    # left.max > range.first
    include_left = !left_entry.nil? && left_entry.value.last > range.first

    bound_min = include_left ? left_entry.value.first : range.first
    sub_map = @range_map.sub_map(bound_min, range.last)

    RangeSet.new(sub_map)
  end

  def head_set(value)
    head_map = @range_map.head_map(value)

    RangeSet.new(head_map)
  end

  def tail_set(value)
    # left.min < value
    left_entry = @range_map.lower_entry(value)

    # left.max > value
    include_left = !left_entry.nil? && left_entry.value.last > value

    bound_min = include_left ? left_entry.value.first : value
    tail_map = @range_map.tail_map(bound_min)

    RangeSet.new(tail_map)
  end

  def add_range(range)
    # ignore empty or reversed ranges
    return self if RangeSet.range_empty?(range)

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

  def add_range_set(range_set)
    return self if range_set == self || range_set.empty?

    range_set.each {|range| add_range(range)}

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

  def remove_range_set(range_set)
    if range_set == self
      clear
    else
      range_set.each {|range| remove_range(range)}
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

  def intersect_range_set(range_set)
    return self if range_set == self

    if range_set.empty? || !bounds_intersected_by?(range_set.bounds)
      clear
      return self
    end

    intersection = range_set.sub_set(bounds).map do |range|
      RangeSet.new.tap do |range_set_item|
        range_set_item.add_range_set(sub_set(range))
        range_set_item.intersect_range(range)
      end
    end.reduce do |acc, range_set_item|
      acc.add_range_set(range_set_item); acc
    end

    @range_map = intersection.range_map
    @min = intersection.min
    @max = intersection.max

    self
  end

  def union_range(range)
    new_range_set = RangeSet.new
    new_range_set.add_range_set(self) unless subset_range?(range)
    new_range_set.add_range(range)
  end

  def union_range_set(range_set)
    new_range_set = clone
    new_range_set.add_range_set(range_set)
  end

  def difference_range(range)
    new_range_set = RangeSet.new

    return new_range_set if subset_range?(range)
    return new_range_set.copy(self) unless bounds_intersected_by?(range)

    unless RangeSet.range_empty?(range)
      new_range_set.add_range_set(head_set(range.first))
      new_range_set.add_range_set(tail_set(range.last))
      new_range_set.remove_range(range)
    end
  end

  def difference_range_set(range_set)
    new_range_set = RangeSet.new

    return new_range_set if range_set == self || empty?

    new_range_set.copy(self)
    new_range_set.remove_range_set(range_set) if !range_set.empty? && bounds_intersected_by?(range_set.bounds)
    new_range_set
  end

  def intersection_range(range)
    new_range_set = RangeSet.new

    return new_range_set unless bounds_intersected_by?(range)
    return new_range_set.copy(self) if subset_range?(range)

    new_range_set.add(sub_set(range))
    new_range_set.intersect_range(range)
  end

  def intersection_range_set(range_set)
    new_range_set = RangeSet.new

    return new_range_set if range_set.empty? || !bounds_intersected_by?(range_set.bounds)

    new_range_set.add_range_set(self)
    new_range_set.intersect_range_set(range_set.sub_set(bounds))
  end

  def convolve_element!(object)
    ranges = map {|range| range.first + object...range.last + object}
    clear
    ranges.each {|range| put(range)}
    update_bounds

    self
  end

  def convolve_range!(range)
    if RangeSet.range_empty?(range)
      clear
    else
      buffer!(-range.first, range.last)
    end
  end

  def convolve_range_set!(range_set)
    range_sets = range_set.map {|range| clone.convolve_range!(range)}
    clear
    range_sets.each {|rs| add_range_set(rs)}

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
