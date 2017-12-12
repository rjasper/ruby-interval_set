require './test/test_helper'

class RangeSetTest < Minitest::Test

  def test_that_it_initializes
    assert IntervalSet[]
  end

  def test_that_bounds_are_initialized
    tree_map = TreeMap.new
    tree_map.put(0, 0...1)
    tree_map.put(2, 2...3)

    interval_set = IntervalSet.new(tree_map)

    assert_equal 0, interval_set.min
    assert_equal 3, interval_set.max
    assert_equal 0...3, interval_set.bounds
  end

  def test_that_it_normalizes_ranges
    assert_equal [0...1, 2...4], IntervalSet[0..1, 2..3, 3..4].to_a
  end

  def test_that_it_equals
    assert_equal IntervalSet[], IntervalSet[]
    assert_equal IntervalSet[0...1], IntervalSet[0...1]
    assert_equal IntervalSet[0...1, 2...3], IntervalSet[0...1, 2...3]
    assert_equal IntervalSet[0...1, 1...2], IntervalSet[0...2]

    assert IntervalSet[0...1, 2...3].eql_set?(IntervalSet[0...1, 2...3])
  end

  def test_that_it_not_equals
    assert IntervalSet[] != IntervalSet[0...1]
    assert IntervalSet[0...1] != IntervalSet[]
    assert IntervalSet[0...1] != IntervalSet[0...2]

    assert !IntervalSet[0...1].eql_set?(IntervalSet[0...2])
  end

  def test_that_it_equals_ranges
    assert IntervalSet[].eql_set?(1...0)
    assert IntervalSet[0...1].eql_set?(0...1)
  end

  def test_that_it_does_not_equal_ranges
    assert !IntervalSet[].eql_set?(0...1)
    assert !IntervalSet[0...1].eql_set?(1...0)
    assert !IntervalSet[0...1].eql_set?(0...2)
  end

  def test_that_empty_converts_to_string
    assert_equal '[]', IntervalSet[].to_s
  end

  def test_that_it_converts_to_string
    assert_equal '[1...2, 3...4]', IntervalSet[1...2, 3...4].to_s
  end

  def test_that_it_is_empty
    assert_empty IntervalSet[]
  end

  def test_that_it_is_not_empty
    assert !IntervalSet[0...1].empty?
  end

  def test_that_it_copies_empty
    original = IntervalSet[]
    copy = IntervalSet[]

    copy = copy.copy(original)

    assert_empty copy
    assert !copy.equal?(original)
  end

  def test_that_it_copies_non_empty
    original = IntervalSet[0...1]
    copy = IntervalSet[]

    copy.copy(original)

    assert_equal IntervalSet[0...1], copy
    assert !copy.equal?(original)
  end

  def test_that_it_clears_data_on_copy
    original = IntervalSet[0...1]
    copy = IntervalSet[2...3]

    copy.copy(original)

    assert_equal IntervalSet[0...1], copy
    assert !copy.equal?(original)
  end

  def test_that_it_clones_empty
    original = IntervalSet[]

    clone = original.clone

    assert_empty clone
    assert !clone.equal?(original)
  end

  def test_that_it_clones_non_empty
    original = IntervalSet[0...1]

    clone = original.clone

    assert_equal IntervalSet[0...1], clone
    assert !clone.equal?(original)
  end

  def test_that_range_includes_interval_set
    interval_set = IntervalSet[1...2]

    assert interval_set.subset?(1...2) # both exact
    assert interval_set.subset?(0...2) # right exact
    assert interval_set.subset?(1...3) # left exact
    assert interval_set.subset?(0...3) # both extra
  end

  def test_that_range_does_not_include_interval_set
    interval_set = IntervalSet[1...2]

    assert !interval_set.subset?(0...1) # on left
    assert !interval_set.subset?(2...3) # on right
    assert !interval_set.subset?(1...1.5) # not right
    assert !interval_set.subset?(1.5...2) # not left
    assert !interval_set.subset?(2...1) # reversed
  end

  def test_that_numeric_is_included
    interval_set = IntervalSet[1...2]

    assert interval_set.include?(1)
    assert interval_set.include?(1.5)
  end

  def test_that_numeric_is_not_included
    interval_set = IntervalSet[1...2]

    assert !interval_set.include?(0)
    assert !interval_set.include?(2)
    assert !interval_set.include?(3)
  end

  def test_that_empty_is_superset_of_empty_range
    # reversed ranges are interpreted as empty
    assert IntervalSet[].superset?(0...0)
    assert IntervalSet[].superset?(1...0)
  end

  def test_that_empty_is_not_superset_of_range
    assert !IntervalSet[].superset?(0...1)
  end

  def test_that_it_is_superset_of_range
    interval_set = IntervalSet[0...1, 2...3]

    assert interval_set.superset?(0...1)
    assert interval_set.superset?(0.5...1)
    assert interval_set.superset?(0...0.5)
    assert interval_set.superset?(0.25...0.75)
    assert interval_set.superset?(2...3)
    assert interval_set.superset?(1...0)
  end

  def test_that_it_is_not_superset_of_range
    interval_set = IntervalSet[0...1, 2...3]

    assert !interval_set.superset?(-2...-1)
    assert !interval_set.superset?(-1...0)
    assert !interval_set.superset?(-1...0.5)
    assert !interval_set.superset?(-1...1)
    assert !interval_set.superset?(-1...1.5)
    assert !interval_set.superset?(-1...2)
    assert !interval_set.superset?(1...4)
    assert !interval_set.superset?(1.5...4)
    assert !interval_set.superset?(2...4)
    assert !interval_set.superset?(2.5...4)
    assert !interval_set.superset?(3...4)
    assert !interval_set.superset?(5...6)
    assert !interval_set.superset?(0...3)
  end

  def test_that_empty_is_superset_of_empty_interval_set
    assert IntervalSet[].superset?(IntervalSet[])
  end

  def test_that_empty_is_not_superset_of_interval_set
    assert !IntervalSet[].superset?(IntervalSet[0...1])
  end

  def test_that_interval_set_is_superset_of_empty
    assert IntervalSet[0...1].superset?(IntervalSet[])
  end

  def test_that_interval_set_is_superset
    interval_set = IntervalSet[1...2, 3...4]

    assert interval_set.superset?(IntervalSet[1...2])
    assert interval_set.superset?(IntervalSet[3...4])
    assert interval_set.superset?(IntervalSet[1...2, 3...4])
  end

  def test_that_interval_set_is_not_superset
    interval_set = IntervalSet[1...2, 3...4]

    assert !interval_set.superset?(IntervalSet[0...3])
    assert !interval_set.superset?(IntervalSet[1...2, 3...4, 5...6])
  end

  def test_that_it_is_subset
    assert IntervalSet[].subset?(1...0)
    assert IntervalSet[].subset?(0...1)
    assert IntervalSet[0...1].subset?(0...1)
    assert IntervalSet[1...2].subset?(0...3)

    assert IntervalSet[] <= IntervalSet[]
    assert IntervalSet[] <= IntervalSet[0...1]
    assert IntervalSet[0...1] <= IntervalSet[0...1]
    assert IntervalSet[1...2] <= IntervalSet[0...3]
  end

  def test_that_it_is_not_subset
    assert !IntervalSet[0...1].subset?(1...0)
    assert !IntervalSet[0...1].subset?(2...3)

    assert !(IntervalSet[0...1] <= IntervalSet[])
    assert !(IntervalSet[0...1] <= IntervalSet[2...3])
  end

  def test_that_it_is_proper_subset
    assert IntervalSet[] < IntervalSet[0...1]
    assert IntervalSet[1...2] < IntervalSet[0...3]
  end

  def test_that_it_is_not_proper_subset
    assert !(IntervalSet[] < IntervalSet[])
    assert !(IntervalSet[0...1] < IntervalSet[])
    assert !(IntervalSet[0...1] < IntervalSet[0...1])
    assert !(IntervalSet[0...1] < IntervalSet[2...3])
  end

  def test_that_it_is_superset
    assert IntervalSet[] >= IntervalSet[]
    assert IntervalSet[0...1] >= IntervalSet[]
    assert IntervalSet[0...1] >= IntervalSet[0...1]
    assert IntervalSet[0...3] >= IntervalSet[1...2]
  end

  def test_that_it_is_not_superset
    assert !(IntervalSet[] >= IntervalSet[0...1])
    assert !(IntervalSet[2...3] >= IntervalSet[0...1])
  end

  def test_that_it_is_proper_superset
    assert IntervalSet[0...1] > IntervalSet[]
    assert IntervalSet[0...3] > IntervalSet[1...2]
  end

  def test_that_it_is_not_proper_superset
    assert !(IntervalSet[] > IntervalSet[])
    assert !(IntervalSet[] >= IntervalSet[0...1])
    assert !(IntervalSet[0...1] > IntervalSet[0...1])
    assert !(IntervalSet[2...3] >= IntervalSet[0...1])
  end

  def test_that_it_intersects_range
    interval_set = IntervalSet[0...1, 2...3]

    assert interval_set.intersect?(0...1)
    assert interval_set.intersect?(0.5...1)
    assert interval_set.intersect?(0...0.5)
    assert interval_set.intersect?(0.25...0.75)
    assert interval_set.intersect?(2...3)
    assert interval_set.intersect?(-1...0.5)
    assert interval_set.intersect?(-1...1)
    assert interval_set.intersect?(-1...1.5)
    assert interval_set.intersect?(-1...2)
    assert interval_set.intersect?(1...4)
    assert interval_set.intersect?(1.5...4)
    assert interval_set.intersect?(2...4)
    assert interval_set.intersect?(2.5...4)
    assert interval_set.intersect?(0...3)
  end

  def test_that_it_not_intersects_range
    interval_set = IntervalSet[0...1, 2...3]

    assert !interval_set.intersect?(-2...-1)
    assert !interval_set.intersect?(-1...0)
    assert !interval_set.intersect?(3...4)
    assert !interval_set.intersect?(5...6)
    assert !interval_set.intersect?(1...0) # reversed range
  end

  def test_that_range_is_within_bounds
    interval_set = IntervalSet[1...2]

    assert interval_set.bounds_intersected_by?(1...2) # both exact
    assert interval_set.bounds_intersected_by?(0...2) # right exact
    assert interval_set.bounds_intersected_by?(1...3) # left exact
    assert interval_set.bounds_intersected_by?(0...3) # both extra
    assert interval_set.bounds_intersected_by?(1...1.5) # not right
    assert interval_set.bounds_intersected_by?(1.5...2) # not left
  end

  def test_that_range_is_not_within_bounds
    interval_set = IntervalSet[1...2]

    assert !interval_set.bounds_intersected_by?(0...1) # on left
    assert !interval_set.bounds_intersected_by?(2...3) # on right
    assert !interval_set.bounds_intersected_by?(1...0) # reversed
  end

  def test_that_empty_has_no_min
    assert_nil IntervalSet[].min
  end

  def test_that_bounds_match_range
    interval_set = IntervalSet[1...2]

    assert_equal 1, interval_set.min
    assert_equal 2, interval_set.max
  end

  def test_that_min_is_updated_after_remove
    interval_set = IntervalSet[0...2]

    interval_set >> (0...1)

    assert_equal 1, interval_set.min
    assert_equal 2, interval_set.max
  end

  def test_that_max_is_updated_after_remove
    interval_set = IntervalSet[0...2]

    interval_set >> (1...2)

    assert_equal 0, interval_set.min
    assert_equal 1, interval_set.max
  end

  def test_that_bounds_are_nil_after_complete_removal
    interval_set = IntervalSet[0...1]

    interval_set >> (0...1)

    assert_nil interval_set.min
    assert_nil interval_set.max
  end

  def test_that_empty_has_no_bounds
    assert_nil IntervalSet[].bounds
  end

  def test_that_it_does_not_add_empty_range
    interval_set = IntervalSet[]
    interval_set << (1...1)

    assert_empty interval_set
  end

  def test_that_it_does_not_add_reversed_range
    interval_set = IntervalSet[]
    interval_set << (1...0)

    assert interval_set.empty?
  end

  def test_that_empty_has_no_max
    assert_nil IntervalSet[].max
  end

  def test_that_it_adds_covering_range
    interval_set = IntervalSet[1...2]

    assert_equal 1, interval_set.count

    interval_set << (0...3)

    assert_equal 1, interval_set.count
    assert_equal IntervalSet[0...3], interval_set
  end

  def test_that_it_adds_range_not_within_bounds
    interval_set = IntervalSet[1...2]

    assert_equal 1, interval_set.count

    interval_set << (3...4)

    assert_equal 2, interval_set.count
    assert_equal IntervalSet[1...2, 3...4], interval_set
  end

  def test_that_included_ranges_are_ignored
    interval_set = IntervalSet[1...2, 3...4, 5...6]

    assert_equal 3, interval_set.count

    interval_set << (3...4)

    assert_equal 3, interval_set.count
    assert_equal IntervalSet[1...2, 3...4, 5...6], interval_set
  end

  def test_that_it_adds_ranges
    interval_set = IntervalSet[]

    interval_set << (0...1)

    assert_equal IntervalSet[0...1], interval_set
  end

  def test_that_it_adds_ranges_left
    interval_set = IntervalSet[0...1]

    interval_set << (-2...-1)

    assert_equal IntervalSet[-2...-1, 0...1], interval_set
  end

  def test_that_it_adds_ranges_right
    interval_set = IntervalSet[-2...-1]

    interval_set << (0...1)

    assert_equal IntervalSet[-2...-1, 0...1], interval_set
  end

  def test_that_it_adds_ranges_left_tight
    interval_set = IntervalSet[0...1]

    interval_set << (-2...0)

    assert_equal IntervalSet[-2...1], interval_set
  end

  def test_that_it_adds_ranges_right_tight
    interval_set = IntervalSet[-2...0]

    interval_set << (0...1)

    assert_equal IntervalSet[-2...1], interval_set
  end

  def test_that_it_adds_left_overlapping
    interval_set = IntervalSet[-1...1]

    interval_set << (-2...0)

    assert_equal IntervalSet[-2...1], interval_set
  end

  def test_that_it_adds_right_overlapping
    interval_set = IntervalSet[-2...0]

    interval_set<< (-1...1)

    assert_equal IntervalSet[-2...1], interval_set
  end

  def test_that_it_adds_interval_set
    interval_set1 = IntervalSet[0...1, 4...5]
    interval_set2 = IntervalSet[2...3, 6...7]

    interval_set1 << interval_set2

    assert_equal IntervalSet[0...1, 2...3, 4...5, 6...7], interval_set1
  end

  def test_that_it_adds_empty_interval_set
    interval_set1 = IntervalSet[0...1, 4...5]
    interval_set2 = IntervalSet[]

    interval_set1 << interval_set2

    assert_equal IntervalSet[0...1, 4...5], interval_set1
  end

  def test_that_it_can_add_itself
    interval_set = IntervalSet[0...1, 4...5]

    interval_set << interval_set

    assert_equal IntervalSet[0...1, 4...5], interval_set
  end

  def test_that_it_removes_from_empty
    interval_set = IntervalSet[] >> (1...2)

    assert_empty interval_set
  end

  def test_that_it_does_not_remove_empty_range
    interval_set = IntervalSet[0...1]
    interval_set >> (0...0)

    assert_equal IntervalSet[0...1], interval_set
  end

  def test_that_it_does_not_remove_reversed_range
    interval_set = IntervalSet[0...1]
    interval_set >> (1...0)

    assert_equal IntervalSet[0...1], interval_set
  end

  def test_that_it_removes_left
    interval_set = IntervalSet[0...1] >> (-2...-1)

    assert_equal IntervalSet[0...1], interval_set
  end

  def test_that_it_removes_right
    interval_set = IntervalSet[0...1] >> (2...3)

    assert_equal IntervalSet[0...1], interval_set
  end

  def test_that_it_removes_tight_left
    interval_set = IntervalSet[0...1]

    interval_set >> (-2...0)

    assert_equal IntervalSet[0...1], interval_set
  end

  def test_that_it_removes_tight_right
    interval_set = IntervalSet[0...1]

    interval_set >> (1...3)

    assert_equal IntervalSet[0...1], interval_set
  end

  def test_that_it_removes_left_overlap
    interval_set = IntervalSet[0...1]

    interval_set >> (-2...0.5)

    assert_equal IntervalSet[0.5...1], interval_set
  end

  def test_that_it_removes_right_overlap
    interval_set = IntervalSet[0...1]

    interval_set >> (0.5...3)

    assert_equal IntervalSet[0...0.5], interval_set
  end

  def test_that_it_removes_inbetween
    interval_set = IntervalSet[0...1]

    interval_set >> (0.25...0.75)

    assert_equal IntervalSet[0...0.25, 0.75...1], interval_set
  end

  def test_that_it_removes_entire_set
    interval_set = IntervalSet[0...1]

    interval_set >> (-1...2)

    assert_empty interval_set
  end

  def test_that_it_removes_bounds
    interval_set = IntervalSet[0...1]

    interval_set >> (0...1)

    assert_empty interval_set
  end

  def test_that_it_removes_interval_set
    interval_set1 = IntervalSet[0...2, 3...5]
    interval_set2 = IntervalSet[1...4, 6...7]

    interval_set1 >> interval_set2

    assert_equal IntervalSet[0...1, 4...5], interval_set1
  end

  def test_that_it_removes_itself
    interval_set = IntervalSet[0...1, 4...5]

    interval_set >> interval_set

    assert_empty interval_set
  end

  def test_that_it_clears
    interval_set = IntervalSet[1...2]

    assert !interval_set.empty?

    interval_set.clear

    assert interval_set.empty?
  end

  def test_that_it_intersects_empty
    assert_empty IntervalSet[] & (0...1)
  end

  def test_that_it_does_not_intersect_improper_range
    assert_empty IntervalSet[0...1] & (0...0)
    assert_empty IntervalSet[0...1] & (1...0)
  end

  def test_that_it_intersects_left
    interval_set = IntervalSet[0...1]

    assert_empty interval_set & (-2...-1)
  end

  def test_that_it_intersects_right
    interval_set = IntervalSet[0...1]

    assert_empty interval_set & (2...3)
  end

  def test_that_it_intersects_tight_left
    interval_set = IntervalSet[0...1]

    assert_empty interval_set & (-2...0)
  end

  def test_that_it_intersects_tight_right
    interval_set = IntervalSet[0...1]

    assert_empty interval_set & (1...3)
  end

  def test_that_it_intersects_left_overlap
    interval_set = IntervalSet[0...1]

    assert_equal IntervalSet[0...0.5], interval_set & (-2...0.5)
  end

  def test_that_it_intersects_right_overlap
    interval_set = IntervalSet[0...1]

    assert_equal IntervalSet[0.5...1], interval_set & (0.5...3)
  end

  def test_that_it_intersects_inbetween
    interval_set = IntervalSet[0...1]

    assert_equal IntervalSet[0.25...0.75], interval_set & (0.25...0.75)
  end

  def test_that_it_intersects_entire_set
    interval_set = IntervalSet[0...1]

    assert_equal IntervalSet[0...1], interval_set & (-1...2)
  end

  def test_that_it_intersects_bounds
    interval_set = IntervalSet[0...1]

    assert_equal IntervalSet[0...1], interval_set & (0...1)
  end

  def test_that_it_intersects_interval_set
    interval_set1 = IntervalSet[0...2, 3...5]
    interval_set2 = IntervalSet[1...4, 6...7]

    assert_equal IntervalSet[1...2, 3...4], interval_set1 & interval_set2
  end

  def test_that_it_intersects_itself
    interval_set = IntervalSet[0...1, 2...3]

    assert_equal IntervalSet[0...1, 2...3], interval_set & interval_set
  end

  def test_that_it_unions_empty
    lhs = IntervalSet[]
    rhs = IntervalSet[]

    assert_empty lhs | rhs
  end

  def test_that_improper_ranges_do_not_affect_union
    assert_equal IntervalSet[0...1], IntervalSet[0...1] | (2...2)
    assert_equal IntervalSet[0...1], IntervalSet[0...1] | (2...1)
  end

  def test_that_it_unions_empty_lhs
    lhs = IntervalSet[]
    rhs = IntervalSet[0...1]

    assert_equal IntervalSet[0...1], lhs | rhs
  end

  def test_that_it_unions_empty_rhs
    lhs = IntervalSet[0...1]
    rhs = IntervalSet[]

    assert_equal IntervalSet[0...1], lhs | rhs
  end

  def test_that_it_unions_left
    assert_equal IntervalSet[-2...-1, 0...1], IntervalSet[0...1] | (-2...-1)
  end

  def test_that_it_unions_right
    assert_equal IntervalSet[0...1, 2...3], IntervalSet[0...1] | (2...3)
  end

  def test_that_it_unions_tight_left
    assert_equal IntervalSet[-2...1], IntervalSet[0...1] | (-2...0)
  end

  def test_that_it_unions_tight_right
    assert_equal IntervalSet[0...3], IntervalSet[0...1] | (1...3)
  end

  def test_that_it_unions_left_overlap
    assert_equal IntervalSet[-2...1], IntervalSet[0...1] | (-2...0.5)
  end

  def test_that_it_unions_right_overlap
    assert_equal IntervalSet[0...3], IntervalSet[0...1] | (0.5...3)
  end

  def test_that_it_unions_inbetween
    assert_equal IntervalSet[0...1], IntervalSet[0...1] | (0.25...0.75)
  end

  def test_that_it_unions_entire_set
    assert_equal IntervalSet[-1...2], IntervalSet[0...1] | (-1...2)
  end

  def test_that_it_unions_bounds
    assert_equal IntervalSet[0...1], IntervalSet[0...1] | (0...1)
  end

  def test_that_it_unions_interval_set
    lhs = IntervalSet[0...1, 4...5]
    rhs = IntervalSet[2...3, 6...7]

    assert_equal IntervalSet[0...1, 2...3, 4...5, 6...7], lhs | rhs
  end

  def test_that_it_unions_itself
    interval_set = IntervalSet[0...1]

    assert_equal IntervalSet[0...1], interval_set | interval_set
  end

  def test_that_it_differences_empty
    lhs = IntervalSet[]
    rhs = IntervalSet[]

    assert_empty lhs - rhs
  end

  def test_that_improper_ranges_do_not_affect_difference
    assert_equal IntervalSet[0...1], IntervalSet[0...1] - (2...2)
    assert_equal IntervalSet[0...1], IntervalSet[0...1] - (2...1)
  end

  def test_that_it_differences_empty_lhs
    lhs = IntervalSet[]
    rhs = IntervalSet[0...1]

    assert_empty lhs - rhs
  end

  def test_that_it_differences_empty_rhs
    lhs = IntervalSet[0...1]
    rhs = IntervalSet[]

    assert_equal IntervalSet[0...1], lhs - rhs
  end

  def test_that_it_differences_left
    assert_equal IntervalSet[0...1], IntervalSet[0...1] - (-2...-1)
  end

  def test_that_it_differences_right
    assert_equal IntervalSet[0...1], IntervalSet[0...1] - (2...3)
  end

  def test_that_it_differences_tight_left
    assert_equal IntervalSet[0...1], IntervalSet[0...1] - (-2...0)
  end

  def test_that_it_differences_tight_right
    assert_equal IntervalSet[0...1], IntervalSet[0...1] - (1...3)
  end

  def test_that_it_differences_left_overlap
    assert_equal IntervalSet[0.5...1], IntervalSet[0...1] - (-2...0.5)
  end

  def test_that_it_differences_right_overlap
    assert_equal IntervalSet[0...0.5], IntervalSet[0...1] - (0.5...3)
  end

  def test_that_it_differences_inbetween
    assert_equal IntervalSet[0...0.25, 0.75...1], IntervalSet[0...1] - (0.25...0.75)
  end

  def test_that_it_differences_entire_set
    assert_empty IntervalSet[0...1] - (-1...2)
  end

  def test_that_it_differences_bounds
    assert_empty IntervalSet[0...1] - (0...1)
  end

  def test_that_it_differences_interval_set
    lhs = IntervalSet[0...2, 3...5]
    rhs = IntervalSet[1...4, 6...7]

    assert_equal IntervalSet[0...1, 4...5], lhs - rhs
  end

  def test_that_it_differences_itself
    interval_set = IntervalSet[0...1]

    assert_empty interval_set - interval_set
  end

  def test_that_it_calculates_xor
    assert_equal IntervalSet[], IntervalSet[] ^ (0..0)
    assert_equal IntervalSet[0...1], IntervalSet[0...1] ^ (0..0)
    assert_equal IntervalSet[0...1], IntervalSet[] ^ (0..1)
    assert_equal IntervalSet[], IntervalSet[0...1] ^ (0..1)
    assert_equal IntervalSet[1...2], IntervalSet[0...1] ^ (0..2)
    assert_equal IntervalSet[0...2], IntervalSet[0...1] ^ (1..2)

    assert_equal IntervalSet[], IntervalSet[] ^ IntervalSet[]
    assert_equal IntervalSet[0...1], IntervalSet[0...1] ^ IntervalSet[]
    assert_equal IntervalSet[0...1], IntervalSet[] ^ IntervalSet[0...1]
    assert_equal IntervalSet[], IntervalSet[0...1] ^ IntervalSet[0...1]
    assert_equal IntervalSet[1...2], IntervalSet[0...1] ^ IntervalSet[0...2]
    assert_equal IntervalSet[0...2], IntervalSet[0...1] ^ IntervalSet[1...2]

    assert_equal IntervalSet[0...1, 2...4, 5...6, 7...8], IntervalSet[0...2, 4...6] ^ IntervalSet[1...5, 7...8]
  end

  def test_that_it_shifts_numeric
    interval_set = IntervalSet[0...1, 2...3]

    assert_equal IntervalSet[1...2, 3...4], interval_set.shift(1)
  end

  def test_that_it_convolves_range
    interval_set = IntervalSet[0...1, 4...5, 9...10]

    assert_equal IntervalSet[-1...7, 8...12], interval_set * (-1...2)
  end

  def test_that_it_buffers_range
    interval_set = IntervalSet[0...1, 4...5, 9...10]

    assert_equal IntervalSet[-1...7, 8...12], interval_set.buffer(1, 2)
  end

  def test_that_it_convolves_reversed_range
    interval_set = IntervalSet[0...10, 20...22]

    assert_empty interval_set * (1...-1)
  end

  def test_that_it_convolves_interval_sets
    lhs = IntervalSet[0...1, 10...12]
    rhs = IntervalSet[-2...1, 1...2]

    assert_equal IntervalSet[-2...3, 8...14], lhs * rhs
  end

  def test_that_it_convolves_empty_interval_sets
    lhs = IntervalSet[]
    rhs = IntervalSet[]

    assert_empty lhs * rhs
  end

  def test_that_it_convolves_empty_lhs_interval_sets
    lhs = IntervalSet[]
    rhs = IntervalSet[-2...1, 1...2]

    assert_empty lhs * rhs
  end

  def test_that_it_convolves_empty_rhs_interval_sets
    lhs = IntervalSet[0...1, 10...12]
    rhs = IntervalSet[]

    assert_empty lhs * rhs
  end

end
