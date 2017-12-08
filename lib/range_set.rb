require 'treemap'
require_relative 'patches/tree_map'

class RangeSet
  include Enumerable

  def initialize(range_map = TreeMap.new)
    unless range_map.instance_of?(TreeMap) || range_map.instance_of?(TreeMap::BoundedMap)
      raise ArgumentError.new("invalid range_map #{range_map}")
    end

    @range_map = range_map
  end

  def empty?
    @range_map.empty?
  end

  def min
    @min
  end

  def max
    @max
  end

  def bounds
    min..max
  end

  def overlapped_by?(range)
    empty? || (range.min <= min && range.max >= max)
  end

  def within_bounds?(range)
    !empty? && range.min < max && range.max > min
  end

  def within_or_touching_bounds?(range)
    !empty? && range.min <= max && range.max >= min
  end

  # whether all elements are present
  def include?(object)
    case object
      when Range
        include_range?(object)
      when RangeSet
        include_range_set?(object)
      else
        include_element?(object)
    end
  end

  def intersect?(object)
    case object
      when Range
        intersect_range?(object)
      when RangeSet
        intersect_range_set?(object)
      else
        include_element?(object)
    end
  end

  def count
    @range_map.count
  end

  def add(object)
    case object
      when Range
        add_range(object)
      when RangeSet
        add_range_set(object)
      else
        raise ArgumentError.new("unexpected object #{object}")
    end
  end

  alias_method :<<, :add
  alias_method :union!, :add

  def remove(object)
    case object
      when Range
        remove_range(object)
      when RangeSet
        remove_range_set(object)
      else
        raise ArgumentError.new("unexpected object #{object}")
    end
  end

  alias_method :>>, :remove
  alias_method :difference!, :remove

  def intersect(object)
    case object
      when Range
        intersect_range(object)
      when RangeSet
        intersect_range_set(object)
      else
        raise ArgumentError.new("unexpected object #{object}")
    end
  end

  alias_method :intersection!, :intersect

  def intersection(object)
    case object
      when Range
        intersection_range(object)
      when RangeSet
        intersection_range_set(object)
      else
        raise ArgumentError.new("unexpected object #{object}")
    end
  end

  alias_method :&, :intersection

  def union(object)
    case object
      when Range
        union_range(object)
      when RangeSet
        union_range_set(object)
      else
        raise ArgumentError.new("unexpected object #{object}")
    end
  end

  alias_method :|, :union
  alias_method :+, :union

  def difference(object)
    case object
      when Range
        difference_range(object)
      when RangeSet
        difference_range_set(object)
      else
        raise ArgumentError.new("unexpected object #{object}")
    end
  end

  alias_method :-, :difference

  def convolve!(object)
    case object
      when Range
        convolve_range!(object)
      when RangeSet
        convolve_range_set!(object)
      else
        convolve_element!(object)
    end
  end

  def convolve(object)
    clone.convolve!(object)
  end

  alias_method :*, :convolve

  def clear
    @range_map.clear
  end

  def each
    @range_map.each_node {|node| yield node.value}
  end

  def clone
    RangeSet.new.copy(self)
  end

  def copy(range_set)
    clear

    range_set.each {|range| put(range)}

    self
  end

  def to_a
    @range_map.values
  end

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

  protected

  def range_map
    @range_map
  end

  def put(range)
    @range_map.put(range.min, range)

    if @min.nil? && @max.nil?
      @min = range.min
      @max = range.max
    else
      @min = [range.min, @min].min
      @max = [range.max, @max].max
    end
  end

  def include_element?(object)
    floor_entry = @range_map.floor_entry(object)

    !floor_entry.nil? && floor_entry.value.max > object
  end

  def include_range?(range)
    return false if empty? || !within_bounds?(range)

    # left.min <= range.min
    left_entry = @range_map.floor_entry(range.min)

    # left.max >= range.max
    !left_entry.nil? && left_entry.value.max >= range.max
  end

  def include_range_set?(range_set)
    return true if range_set == self || range_set.empty?
    return false if empty? || !range_set.within_bounds?(bounds)

    range_set.all? {|range| include_range?(range)}
  end

  def intersect_range?(range)
    return false unless within_bounds?(range)

    # left.min < range.max
    left_entry = @range_map.lower_entry(range.max)

    # left.max > range.min
    !left_entry.nil? && left_entry.value.max > range.min
  end

  def intersect_range_set?(range_set)
    return false if empty? || !within_bounds?(range_set.bounds)

    sub_set(range_set.bounds).any? {|range| intersect_range?(range)}
  end

  def sub_set(range)
    # left.min < range.min
    left_entry = @range_map.lower_entry(range.min)

    # left.max > range.min
    include_left = !left_entry.nil? && left_entry.value.max > range.min

    bound_min = include_left ? left_entry.value.min : range.min
    sub_map = @range_map.sub_map(bound_min, range.max)

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
    include_left = !left_entry.nil? && left_entry.value.max > value

    bound_min = include_left ? left_entry.value.min : value
    tail_map = @range_map.tail_map(bound_min)

    RangeSet.new(tail_map)
  end

  def add_range(range)
    # ignore empty or reversed ranges
    return self if range.first >= range.last

    # short cut
    unless within_or_touching_bounds?(range)
      put(range)
      return self
    end

    # short cut
    if overlapped_by?(range)
      clear
      put(range)
      return self
    end

    # range.min <= core.min <= range.max
    core = @range_map.sub_map(range.min, true, range.max, true)

    # short cut if range already included
    if !core.empty? && core.first_entry == core.last_entry
      core_range = core.first_entry.value

      return self if core_range.min == range.min && core_range.max == range.max
    end

    # left.min < range.min
    left_entry = @range_map.lower_entry(range.min)
    # right.min <= range.max
    right_entry = core.empty? ? left_entry : core.last_entry

    # determine boundaries

    # left.max >= range.min
    include_left = !left_entry.nil? && left_entry.value.max >= range.min
    # right.max > range.max
    include_right = !right_entry.nil? && right_entry.value.max > range.max

    left_boundary = include_left ? left_entry.key : range.min
    right_boundary = include_right ? right_entry.value.max : range.max

    @range_map.remove(left_boundary) if include_left

    core.keys.each {|key| @range_map.remove(key)}

    # add range

    if !include_left && !include_right
      put(range)
    else
      put(left_boundary..right_boundary)
    end

    self
  end

  def add_range_set(range_set)
    return self if range_set == self || range_set.empty?

    range_set.each {|range| add_range(range)}

    self
  end

  def remove_range(range)
    return self unless within_bounds?(range)

    # range.min <= core.min <= range.max
    core = @range_map.sub_map(range.min, true, range.max, false)

    # left.min < range.min
    left_entry = @range_map.lower_entry(range.min)
    # right.min < range.max
    right_entry = core.empty? ? left_entry : core.last_entry

    # left.max > range.to
    include_left = !left_entry.nil? && left_entry.value.max > range.min
    # right.max > range.max
    include_right = !right_entry.nil? && right_entry.value.max > range.max

    core.keys.each {|key| @range_map.remove(key)}

    # right first since right might be same as left
    put(range.max..right_entry.value.max) if include_right
    put(left_entry.key..range.min) if include_left

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
    unless within_bounds?(range)
      clear
      return self
    end

    return self if overlapped_by?(range)

    # left_map.min < range.min
    left_map = @range_map.head_map(range.min, false)
    # right_map.min >= range.max
    right_map = @range_map.tail_map(range.max, true)

    # left.min < range.min
    left_entry = left_map.last_entry
    # right.min < range.max
    right_entry = @range_map.lower_entry(range.max)

    # left.max > range.min
    include_left = !left_entry.nil? && left_entry.value.max > range.min
    # right.max > right.max
    include_right = !right_entry.nil? && right_entry.value.max > range.max

    left_map.keys.each {|key| @range_map.remove(key)}
    right_map.keys.each {|key| @range_map.remove(key)}

    put(range.min..[left_entry.value.max, range.max].min) if include_left
    put([right_entry.key, range.min].max..range.max) if include_right

    self
  end

  def intersect_range_set(range_set)
    return self if range_set == self

    if range_set.empty? || !within_bounds?(range_set.bounds)
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

    self
  end

  def union_range(range)
    new_range_set = RangeSet.new
    new_range_set.add_range_set(self) unless overlapped_by?(range)
    new_range_set.add_range(range)
  end

  def union_range_set(range_set)
    new_range_set = clone
    new_range_set.add_range_set(range_set)
  end

  def difference_range(range)
    new_range_set = RangeSet.new

    return new_range_set if overlapped_by?(range)
    return new_range_set.copy(self) unless within_bounds?(range)

    new_range_set.add_range_set(head_set(range.min))
    new_range_set.add_range_set(tail_set(range.max))
    new_range_set.remove_range(range)
  end

  def difference_range_set(range_set)
    new_range_set = RangeSet.new

    return new_range_set if range_set == self || empty?

    new_range_set.copy(self)
    new_range_set.remove_range_set(range_set) if !range_set.empty? && within_bounds?(range_set.bounds)
    new_range_set
  end

  def intersection_range(range)
    new_range_set = RangeSet.new

    return new_range_set unless within_bounds?(range)
    return new_range_set.add_range(range) if overlapped_by?(range)

    new_range_set.add(sub_set(range))
    new_range_set.intersect_range(range)
  end

  def intersection_range_set(range_set)
    new_range_set = RangeSet.new

    return new_range_set if range_set.empty? || !within_bounds?(range_set.bounds)

    new_range_set.add_range_set(self)
    new_range_set.intersect_range_set(range_set.sub_set(bounds))
  end

  def convolve_element!(object)
    ranges = map {|range| range.min + object..range.max + object}
    clear
    ranges.each {|range| put(range)}

    self
  end

  def convolve_range!(range)
    ranges = map {|r| r.min + range.min..r.max + range.max}
    clear
    ranges.each {|r| add_range(r)}

    self
  end

  def convolve_range_set!(range_set)
    range_sets = range_set.map {|range| clone.convolve_range!(range)}
    clear
    range_sets.each {|rs| add_range_set(rs)}

    self
  end

end
