require_relative 'version'
require 'treemap-fork'

class RangeSet
  include Enumerable

  def self.[](*ranges)
    RangeSet.new.tap do |range_set|
      ranges.each {|range| range_set << range}
    end
  end

  def initialize(range_map = TreeMap.new)
    unless range_map.instance_of?(TreeMap) || range_map.instance_of?(TreeMap::BoundedMap)
      raise ArgumentError.new("invalid range_map #{range_map}")
    end

    @range_map = range_map

    update_bounds
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
    empty? ? nil : min...max
  end

  def eql?(other)
    return false if count != other.count
    return false if bounds != other.bounds

    lhs_iter = enum_for
    rhs_iter = other.enum_for

    count.times.all? {lhs_iter.next == rhs_iter.next}
  end

  alias_method :==, :eql?

  def eql_set?(object)
    case object
      when Range
        eql_range?(object)
      when RangeSet
        eql?(object)
      else
        false
    end
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

  alias_method :===, :include?
  alias_method :superset?, :include?
  alias_method :>=, :include?

  def included_by?(object)
    return true if empty?

    case object
      when Range
        included_by_range?(object)
      when RangeSet
        object.include_range_set?(self)
      else
        false
    end
  end

  alias_method :subset?, :included_by?
  alias_method :<=, :included_by?

  def proper_superset?(object)
    !eql_set?(object) && superset?(object)
  end

  alias_method :>, :proper_superset?

  def proper_subset?(object)
    !eql_set?(object) && subset?(object)
  end

  alias_method :<, :proper_subset?

  def bounds_intersected_by?(range)
    return false if RangeSet::range_empty?(range)

    !empty? && range.first < max && range.last > min
  end

  def bounds_intersected_or_touched_by?(range)
    return false if RangeSet::range_empty?(range)

    !empty? && range.first <= max && range.last >= min
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

  def shift!(object)
    convolve_element!(object)
  end

  def shift(object)
    clone.shift!(object)
  end

  def buffer!(range)
    convolve_range!(range)
  end

  def buffer(range)
    clone.buffer!(range)
  end

  def clear
    @range_map.clear
    @min = nil
    @max = nil
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
    @min = range_set.min
    @max = range_set.max

    self
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

  alias_method :inspect, :to_s

  protected

  def range_map
    @range_map
  end

  def put(range)
    @range_map.put(range.first, RangeSet::normalize_range(range))
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

  def include_element?(object)
    floor_entry = @range_map.floor_entry(object)

    !floor_entry.nil? && floor_entry.value.last > object
  end

  def include_range?(range)
    return true if RangeSet::range_empty?(range)
    return false if empty? || !bounds_intersected_by?(range)

    # left.min <= range.first
    left_entry = @range_map.floor_entry(range.first)

    # left.max >= range.last
    !left_entry.nil? && left_entry.value.last >= range.last
  end

  def include_range_set?(range_set)
    return true if range_set == self || range_set.empty?
    return false if empty? || !range_set.bounds_intersected_by?(bounds)

    range_set.all? {|range| include_range?(range)}
  end

  def included_by_range?(range)
    return false if RangeSet::range_empty?(range)

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
    return true if empty? && RangeSet::range_empty?(range)

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
    return self if RangeSet::range_empty?(range)

    # short cut
    unless bounds_intersected_or_touched_by?(range)
      put_and_update_bounds(range)
      return self
    end

    # short cut
    if included_by_range?(range)
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

    return self if included_by_range?(range)

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
    new_range_set.add_range_set(self) unless included_by_range?(range)
    new_range_set.add_range(range)
  end

  def union_range_set(range_set)
    new_range_set = clone
    new_range_set.add_range_set(range_set)
  end

  def difference_range(range)
    new_range_set = RangeSet.new

    return new_range_set if included_by_range?(range)
    return new_range_set.copy(self) unless bounds_intersected_by?(range)

    unless RangeSet::range_empty?(range)
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
    return new_range_set.copy(self) if included_by_range?(range)

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
    ranges = map do |r|
      r.first + range.first...r.last + range.last
    end.select do |r|
      r.first < r.last
    end

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

end
