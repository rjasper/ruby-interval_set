require './test/test_helper'

class RangeSetTest < Minitest::Test

  def test_that_it_initializes
    assert RangeSet[]
  end

  def test_that_bounds_are_initialized
    tree_map = TreeMap.new
    tree_map.put(0, 0...1)
    tree_map.put(2, 2...3)

    range_set = RangeSet.new(tree_map)

    assert_equal 0, range_set.min
    assert_equal 3, range_set.max
    assert_equal 0...3, range_set.bounds
  end

  def test_that_it_normalizes_ranges
    assert_equal [0...1, 2...4], RangeSet[0..1, 2..3, 3..4].to_a
  end

  def test_that_it_equals
    assert_equal RangeSet[], RangeSet[]
    assert_equal RangeSet[0...1], RangeSet[0...1]
    assert_equal RangeSet[0...1, 2...3], RangeSet[0...1, 2...3]
    assert_equal RangeSet[0...1, 1...2], RangeSet[0...2]

    assert RangeSet[0...1, 2...3].eql_set?(RangeSet[0...1, 2...3])
  end

  def test_that_it_not_equals
    assert RangeSet[] != RangeSet[0...1]
    assert RangeSet[0...1] != RangeSet[]
    assert RangeSet[0...1] != RangeSet[0...2]

    assert !RangeSet[0...1].eql_set?(RangeSet[0...2])
  end

  def test_that_it_does_not_equal_element
    assert !RangeSet[].eql_set?(0)
    assert !RangeSet[0...1].eql_set?(0)
  end

  def test_that_it_equals_ranges
    assert RangeSet[].eql_set?(1...0)
    assert RangeSet[0...1].eql_set?(0...1)
  end

  def test_that_it_does_not_equal_ranges
    assert !RangeSet[].eql_set?(0...1)
    assert !RangeSet[0...1].eql_set?(1...0)
    assert !RangeSet[0...1].eql_set?(0...2)
  end

  def test_that_empty_converts_to_string
    assert_equal '[]', RangeSet[].to_s
  end

  def test_that_it_converts_to_string
    assert_equal '[1...2, 3...4]', RangeSet[1...2, 3...4].to_s
  end

  def test_that_it_is_empty
    assert_empty RangeSet[]
  end

  def test_that_it_is_not_empty
    assert !RangeSet[0...1].empty?
  end

  def test_that_it_copies_empty
    original = RangeSet[]
    copy = RangeSet[]

    copy = copy.copy(original)

    assert_empty copy
    assert !copy.equal?(original)
  end

  def test_that_it_copies_non_empty
    original = RangeSet[0...1]
    copy = RangeSet[]

    copy.copy(original)

    assert_equal RangeSet[0...1], copy
    assert !copy.equal?(original)
  end

  def test_that_it_clears_data_on_copy
    original = RangeSet[0...1]
    copy = RangeSet[2...3]

    copy.copy(original)

    assert_equal RangeSet[0...1], copy
    assert !copy.equal?(original)
  end

  def test_that_it_clones_empty
    original = RangeSet[]

    clone = original.clone

    assert_empty clone
    assert !clone.equal?(original)
  end

  def test_that_it_clones_non_empty
    original = RangeSet[0...1]

    clone = original.clone

    assert_equal RangeSet[0...1], clone
    assert !clone.equal?(original)
  end

  def test_that_range_includes_range_set
    range_set = RangeSet[1...2]

    assert range_set.included_by?(1...2) # both exact
    assert range_set.included_by?(0...2) # right exact
    assert range_set.included_by?(1...3) # left exact
    assert range_set.included_by?(0...3) # both extra
  end

  def test_that_range_does_not_include_range_set
    range_set = RangeSet[1...2]

    assert !range_set.included_by?(0...1) # on left
    assert !range_set.included_by?(2...3) # on right
    assert !range_set.included_by?(1...1.5) # not right
    assert !range_set.included_by?(1.5...2) # not left
    assert !range_set.included_by?(2...1) # reversed
  end

  def test_that_numeric_is_included
    range_set = RangeSet[1...2]

    assert range_set.include?(1)
    assert range_set.include?(1.5)
  end

  def test_that_numeric_is_not_included
    range_set = RangeSet[1...2]

    assert !range_set.include?(0)
    assert !range_set.include?(2)
    assert !range_set.include?(3)
  end

  def test_that_empty_is_superset_of_empty_range
    # reversed ranges are interpreted as empty
    assert RangeSet[].superset?(0...0)
    assert RangeSet[].superset?(1...0)
  end

  def test_that_empty_is_not_superset_of_range
    assert !RangeSet[].superset?(0...1)
  end

  def test_that_it_is_superset_of_range
    range_set = RangeSet[0...1, 2...3]

    assert range_set.superset?(0...1)
    assert range_set.superset?(0.5...1)
    assert range_set.superset?(0...0.5)
    assert range_set.superset?(0.25...0.75)
    assert range_set.superset?(2...3)
    assert range_set.superset?(1...0)
  end

  def test_that_it_is_not_superset_of_range
    range_set = RangeSet[0...1, 2...3]

    assert !range_set.superset?(-2...-1)
    assert !range_set.superset?(-1...0)
    assert !range_set.superset?(-1...0.5)
    assert !range_set.superset?(-1...1)
    assert !range_set.superset?(-1...1.5)
    assert !range_set.superset?(-1...2)
    assert !range_set.superset?(1...4)
    assert !range_set.superset?(1.5...4)
    assert !range_set.superset?(2...4)
    assert !range_set.superset?(2.5...4)
    assert !range_set.superset?(3...4)
    assert !range_set.superset?(5...6)
    assert !range_set.superset?(0...3)
  end

  def test_that_empty_is_superset_of_empty_range_set
    assert RangeSet[].superset?(RangeSet[])
  end

  def test_that_empty_is_not_superset_of_range_set
    assert !RangeSet[].superset?(RangeSet[0...1])
  end

  def test_that_range_set_is_superset_of_empty
    assert RangeSet[0...1].superset?(RangeSet[])
  end

  def test_that_range_set_is_superset
    range_set = RangeSet[1...2, 3...4]

    assert range_set.superset?(RangeSet[1...2])
    assert range_set.superset?(RangeSet[3...4])
    assert range_set.superset?(RangeSet[1...2, 3...4])
  end

  def test_that_range_set_is_not_superset
    range_set = RangeSet[1...2, 3...4]

    assert !range_set.superset?(RangeSet[0...3])
    assert !range_set.superset?(RangeSet[1...2, 3...4, 5...6])
  end

  def test_that_it_is_subset
    assert RangeSet[].subset?(0)

    assert RangeSet[].subset?(1...0)
    assert RangeSet[].subset?(0...1)
    assert RangeSet[0...1].subset?(0...1)
    assert RangeSet[1...2].subset?(0...3)

    assert RangeSet[] <= RangeSet[]
    assert RangeSet[] <= RangeSet[0...1]
    assert RangeSet[0...1] <= RangeSet[0...1]
    assert RangeSet[1...2] <= RangeSet[0...3]
  end

  def test_that_it_is_not_subset
    assert !RangeSet[0...1].subset?(2)

    assert !RangeSet[0...1].subset?(1...0)
    assert !RangeSet[0...1].subset?(2...3)

    assert !(RangeSet[0...1] <= RangeSet[])
    assert !(RangeSet[0...1] <= RangeSet[2...3])
  end

  def test_that_it_is_proper_subset
    assert RangeSet[] < RangeSet[0...1]
    assert RangeSet[1...2] < RangeSet[0...3]
  end

  def test_that_it_is_not_proper_subset
    assert !(RangeSet[] < RangeSet[])
    assert !(RangeSet[0...1] < RangeSet[])
    assert !(RangeSet[0...1] < RangeSet[0...1])
    assert !(RangeSet[0...1] < RangeSet[2...3])
  end

  def test_that_it_is_superset
    assert RangeSet[] >= RangeSet[]
    assert RangeSet[0...1] >= RangeSet[]
    assert RangeSet[0...1] >= RangeSet[0...1]
    assert RangeSet[0...3] >= RangeSet[1...2]
  end

  def test_that_it_is_not_superset
    assert !(RangeSet[] >= RangeSet[0...1])
    assert !(RangeSet[2...3] >= RangeSet[0...1])
  end

  def test_that_it_is_proper_superset
    assert RangeSet[0...1] > RangeSet[]
    assert RangeSet[0...3] > RangeSet[1...2]
  end

  def test_that_it_is_not_proper_superset
    assert !(RangeSet[] > RangeSet[])
    assert !(RangeSet[] >= RangeSet[0...1])
    assert !(RangeSet[0...1] > RangeSet[0...1])
    assert !(RangeSet[2...3] >= RangeSet[0...1])
  end

  def test_that_it_intersects_range
    range_set = RangeSet[0...1, 2...3]

    assert range_set.intersect?(0...1)
    assert range_set.intersect?(0.5...1)
    assert range_set.intersect?(0...0.5)
    assert range_set.intersect?(0.25...0.75)
    assert range_set.intersect?(2...3)
    assert range_set.intersect?(-1...0.5)
    assert range_set.intersect?(-1...1)
    assert range_set.intersect?(-1...1.5)
    assert range_set.intersect?(-1...2)
    assert range_set.intersect?(1...4)
    assert range_set.intersect?(1.5...4)
    assert range_set.intersect?(2...4)
    assert range_set.intersect?(2.5...4)
    assert range_set.intersect?(0...3)
  end

  def test_that_it_not_intersects_range
    range_set = RangeSet[0...1, 2...3]

    assert !range_set.intersect?(-2...-1)
    assert !range_set.intersect?(-1...0)
    assert !range_set.intersect?(3...4)
    assert !range_set.intersect?(5...6)
    assert !range_set.intersect?(1...0) # reversed range
  end

  def test_that_range_is_within_bounds
    range_set = RangeSet[1...2]

    assert range_set.bounds_intersected_by?(1...2) # both exact
    assert range_set.bounds_intersected_by?(0...2) # right exact
    assert range_set.bounds_intersected_by?(1...3) # left exact
    assert range_set.bounds_intersected_by?(0...3) # both extra
    assert range_set.bounds_intersected_by?(1...1.5) # not right
    assert range_set.bounds_intersected_by?(1.5...2) # not left
  end

  def test_that_range_is_not_within_bounds
    range_set = RangeSet[1...2]

    assert !range_set.bounds_intersected_by?(0...1) # on left
    assert !range_set.bounds_intersected_by?(2...3) # on right
    assert !range_set.bounds_intersected_by?(1...0) # reversed
  end

  def test_that_empty_has_no_min
    assert_nil RangeSet[].min
  end

  def test_that_bounds_match_range
    range_set = RangeSet[1...2]

    assert_equal 1, range_set.min
    assert_equal 2, range_set.max
  end

  def test_that_min_is_updated_after_remove
    range_set = RangeSet[0...2]

    range_set >> (0...1)

    assert_equal 1, range_set.min
    assert_equal 2, range_set.max
  end

  def test_that_max_is_updated_after_remove
    range_set = RangeSet[0...2]

    range_set >> (1...2)

    assert_equal 0, range_set.min
    assert_equal 1, range_set.max
  end

  def test_that_bounds_are_nil_after_complete_removal
    range_set = RangeSet[0...1]

    range_set >> (0...1)

    assert_nil range_set.min
    assert_nil range_set.max
  end

  def test_that_empty_has_no_bounds
    assert_nil RangeSet[].bounds
  end

  def test_that_it_does_not_add_empty_range
    range_set = RangeSet[]
    range_set << (1...1)

    assert_empty range_set
  end

  def test_that_it_does_not_add_reversed_range
    range_set = RangeSet[]
    range_set << (1...0)

    assert range_set.empty?
  end

  def test_that_empty_has_no_max
    assert_nil RangeSet[].max
  end

  def test_that_it_adds_covering_range
    range_set = RangeSet[1...2]

    assert_equal 1, range_set.count

    range_set << (0...3)

    assert_equal 1, range_set.count
    assert_equal RangeSet[0...3], range_set
  end

  def test_that_it_adds_range_not_within_bounds
    range_set = RangeSet[1...2]

    assert_equal 1, range_set.count

    range_set << (3...4)

    assert_equal 2, range_set.count
    assert_equal RangeSet[1...2, 3...4], range_set
  end

  def test_that_included_ranges_are_ignored
    range_set = RangeSet[1...2, 3...4, 5...6]

    assert_equal 3, range_set.count

    range_set << (3...4)

    assert_equal 3, range_set.count
    assert_equal RangeSet[1...2, 3...4, 5...6], range_set
  end

  def test_that_it_adds_ranges
    range_set = RangeSet[]

    range_set << (0...1)

    assert_equal RangeSet[0...1], range_set
  end

  def test_that_it_adds_ranges_left
    range_set = RangeSet[0...1]

    range_set << (-2...-1)

    assert_equal RangeSet[-2...-1, 0...1], range_set
  end

  def test_that_it_adds_ranges_right
    range_set = RangeSet[-2...-1]

    range_set << (0...1)

    assert_equal RangeSet[-2...-1, 0...1], range_set
  end

  def test_that_it_adds_ranges_left_tight
    range_set = RangeSet[0...1]

    range_set << (-2...0)

    assert_equal RangeSet[-2...1], range_set
  end

  def test_that_it_adds_ranges_right_tight
    range_set = RangeSet[-2...0]

    range_set << (0...1)

    assert_equal RangeSet[-2...1], range_set
  end

  def test_that_it_adds_left_overlapping
    range_set = RangeSet[-1...1]

    range_set << (-2...0)

    assert_equal RangeSet[-2...1], range_set
  end

  def test_that_it_adds_right_overlapping
    range_set = RangeSet[-2...0]

    range_set<< (-1...1)

    assert_equal RangeSet[-2...1], range_set
  end

  def test_that_it_adds_range_set
    range_set1 = RangeSet[0...1, 4...5]
    range_set2 = RangeSet[2...3, 6...7]

    range_set1 << range_set2

    assert_equal RangeSet[0...1, 2...3, 4...5, 6...7], range_set1
  end

  def test_that_it_adds_empty_range_set
    range_set1 = RangeSet[0...1, 4...5]
    range_set2 = RangeSet[]

    range_set1 << range_set2

    assert_equal RangeSet[0...1, 4...5], range_set1
  end

  def test_that_it_can_add_itself
    range_set = RangeSet[0...1, 4...5]

    range_set << range_set

    assert_equal RangeSet[0...1, 4...5], range_set
  end

  def test_that_it_removes_from_empty
    range_set = RangeSet[] >> (1...2)

    assert_empty range_set
  end

  def test_that_it_does_not_remove_empty_range
    range_set = RangeSet[0...1]
    range_set >> (0...0)

    assert_equal RangeSet[0...1], range_set
  end

  def test_that_it_does_not_remove_reversed_range
    range_set = RangeSet[0...1]
    range_set >> (1...0)

    assert_equal RangeSet[0...1], range_set
  end

  def test_that_it_removes_left
    range_set = RangeSet[0...1] >> (-2...-1)

    assert_equal RangeSet[0...1], range_set
  end

  def test_that_it_removes_right
    range_set = RangeSet[0...1] >> (2...3)

    assert_equal RangeSet[0...1], range_set
  end

  def test_that_it_removes_tight_left
    range_set = RangeSet[0...1]

    range_set >> (-2...0)

    assert_equal RangeSet[0...1], range_set
  end

  def test_that_it_removes_tight_right
    range_set = RangeSet[0...1]

    range_set >> (1...3)

    assert_equal RangeSet[0...1], range_set
  end

  def test_that_it_removes_left_overlap
    range_set = RangeSet[0...1]

    range_set >> (-2...0.5)

    assert_equal RangeSet[0.5...1], range_set
  end

  def test_that_it_removes_right_overlap
    range_set = RangeSet[0...1]

    range_set >> (0.5...3)

    assert_equal RangeSet[0...0.5], range_set
  end

  def test_that_it_removes_inbetween
    range_set = RangeSet[0...1]

    range_set >> (0.25...0.75)

    assert_equal RangeSet[0...0.25, 0.75...1], range_set
  end

  def test_that_it_removes_entire_set
    range_set = RangeSet[0...1]

    range_set >> (-1...2)

    assert_empty range_set
  end

  def test_that_it_removes_bounds
    range_set = RangeSet[0...1]

    range_set >> (0...1)

    assert_empty range_set
  end

  def test_that_it_removes_range_set
    range_set1 = RangeSet[0...2, 3...5]
    range_set2 = RangeSet[1...4, 6...7]

    range_set1 >> range_set2

    assert_equal RangeSet[0...1, 4...5], range_set1
  end

  def test_that_it_removes_itself
    range_set = RangeSet[0...1, 4...5]

    range_set >> range_set

    assert_empty range_set
  end

  def test_that_it_clears
    range_set = RangeSet[1...2]

    assert !range_set.empty?

    range_set.clear

    assert range_set.empty?
  end

  def test_that_it_intersects_empty
    assert_empty RangeSet[] & (0...1)
  end

  def test_that_it_does_not_intersect_improper_range
    assert_empty RangeSet[0...1] & (0...0)
    assert_empty RangeSet[0...1] & (1...0)
  end

  def test_that_it_intersects_left
    range_set = RangeSet[0...1]

    assert_empty range_set & (-2...-1)
  end

  def test_that_it_intersects_right
    range_set = RangeSet[0...1]

    assert_empty range_set & (2...3)
  end

  def test_that_it_intersects_tight_left
    range_set = RangeSet[0...1]

    assert_empty range_set & (-2...0)
  end

  def test_that_it_intersects_tight_right
    range_set = RangeSet[0...1]

    assert_empty range_set & (1...3)
  end

  def test_that_it_intersects_left_overlap
    range_set = RangeSet[0...1]

    assert_equal RangeSet[0...0.5], range_set & (-2...0.5)
  end

  def test_that_it_intersects_right_overlap
    range_set = RangeSet[0...1]

    assert_equal RangeSet[0.5...1], range_set & (0.5...3)
  end

  def test_that_it_intersects_inbetween
    range_set = RangeSet[0...1]

    assert_equal RangeSet[0.25...0.75], range_set & (0.25...0.75)
  end

  def test_that_it_intersects_entire_set
    range_set = RangeSet[0...1]

    assert_equal RangeSet[0...1], range_set & (-1...2)
  end

  def test_that_it_intersects_bounds
    range_set = RangeSet[0...1]

    assert_equal RangeSet[0...1], range_set & (0...1)
  end

  def test_that_it_intersects_range_set
    range_set1 = RangeSet[0...2, 3...5]
    range_set2 = RangeSet[1...4, 6...7]

    assert_equal RangeSet[1...2, 3...4], range_set1 & range_set2
  end

  def test_that_it_intersects_itself
    range_set = RangeSet[0...1, 2...3]

    assert_equal RangeSet[0...1, 2...3], range_set & range_set
  end

  def test_that_it_unions_empty
    lhs = RangeSet[]
    rhs = RangeSet[]

    assert_empty lhs | rhs
  end

  def test_that_improper_ranges_do_not_affect_union
    assert_equal RangeSet[0...1], RangeSet[0...1] | (2...2)
    assert_equal RangeSet[0...1], RangeSet[0...1] | (2...1)
  end

  def test_that_it_unions_empty_lhs
    lhs = RangeSet[]
    rhs = RangeSet[0...1]

    assert_equal RangeSet[0...1], lhs | rhs
  end

  def test_that_it_unions_empty_rhs
    lhs = RangeSet[0...1]
    rhs = RangeSet[]

    assert_equal RangeSet[0...1], lhs | rhs
  end

  def test_that_it_unions_left
    assert_equal RangeSet[-2...-1, 0...1], RangeSet[0...1] | (-2...-1)
  end

  def test_that_it_unions_right
    assert_equal RangeSet[0...1, 2...3], RangeSet[0...1] | (2...3)
  end

  def test_that_it_unions_tight_left
    assert_equal RangeSet[-2...1], RangeSet[0...1] | (-2...0)
  end

  def test_that_it_unions_tight_right
    assert_equal RangeSet[0...3], RangeSet[0...1] | (1...3)
  end

  def test_that_it_unions_left_overlap
    assert_equal RangeSet[-2...1], RangeSet[0...1] | (-2...0.5)
  end

  def test_that_it_unions_right_overlap
    assert_equal RangeSet[0...3], RangeSet[0...1] | (0.5...3)
  end

  def test_that_it_unions_inbetween
    assert_equal RangeSet[0...1], RangeSet[0...1] | (0.25...0.75)
  end

  def test_that_it_unions_entire_set
    assert_equal RangeSet[-1...2], RangeSet[0...1] | (-1...2)
  end

  def test_that_it_unions_bounds
    assert_equal RangeSet[0...1], RangeSet[0...1] | (0...1)
  end

  def test_that_it_unions_range_set
    lhs = RangeSet[0...1, 4...5]
    rhs = RangeSet[2...3, 6...7]

    assert_equal RangeSet[0...1, 2...3, 4...5, 6...7], lhs | rhs
  end

  def test_that_it_unions_itself
    range_set = RangeSet[0...1]

    assert_equal RangeSet[0...1], range_set | range_set
  end

  def test_that_it_differences_empty
    lhs = RangeSet[]
    rhs = RangeSet[]

    assert_empty lhs - rhs
  end

  def test_that_improper_ranges_do_not_affect_difference
    assert_equal RangeSet[0...1], RangeSet[0...1] - (2...2)
    assert_equal RangeSet[0...1], RangeSet[0...1] - (2...1)
  end

  def test_that_it_differences_empty_lhs
    lhs = RangeSet[]
    rhs = RangeSet[0...1]

    assert_empty lhs - rhs
  end

  def test_that_it_differences_empty_rhs
    lhs = RangeSet[0...1]
    rhs = RangeSet[]

    assert_equal RangeSet[0...1], lhs - rhs
  end

  def test_that_it_differences_left
    assert_equal RangeSet[0...1], RangeSet[0...1] - (-2...-1)
  end

  def test_that_it_differences_right
    assert_equal RangeSet[0...1], RangeSet[0...1] - (2...3)
  end

  def test_that_it_differences_tight_left
    assert_equal RangeSet[0...1], RangeSet[0...1] - (-2...0)
  end

  def test_that_it_differences_tight_right
    assert_equal RangeSet[0...1], RangeSet[0...1] - (1...3)
  end

  def test_that_it_differences_left_overlap
    assert_equal RangeSet[0.5...1], RangeSet[0...1] - (-2...0.5)
  end

  def test_that_it_differences_right_overlap
    assert_equal RangeSet[0...0.5], RangeSet[0...1] - (0.5...3)
  end

  def test_that_it_differences_inbetween
    assert_equal RangeSet[0...0.25, 0.75...1], RangeSet[0...1] - (0.25...0.75)
  end

  def test_that_it_differences_entire_set
    assert_empty RangeSet[0...1] - (-1...2)
  end

  def test_that_it_differences_bounds
    assert_empty RangeSet[0...1] - (0...1)
  end

  def test_that_it_differences_range_set
    lhs = RangeSet[0...2, 3...5]
    rhs = RangeSet[1...4, 6...7]

    assert_equal RangeSet[0...1, 4...5], lhs - rhs
  end

  def test_that_it_differences_itself
    range_set = RangeSet[0...1]

    assert_empty range_set - range_set
  end

  def test_that_it_convolves_numeric
    range_set = RangeSet[0...1, 2...3]

    assert_equal RangeSet[1...2, 3...4], range_set * 1
  end

  def test_that_it_shifts_numeric
    range_set = RangeSet[0...1, 2...3]

    assert_equal RangeSet[1...2, 3...4], range_set.shift(1)
  end

  def test_that_it_convolves_range
    range_set = RangeSet[0...1, 4...5, 9...10]

    assert_equal RangeSet[-1...7, 8...12], range_set * (-1...2)
  end

  def test_that_it_buffers_range
    range_set = RangeSet[0...1, 4...5, 9...10]

    assert_equal RangeSet[-1...7, 8...12], range_set.buffer(1, 2)
  end

  def test_that_it_convolves_reversed_range
    range_set = RangeSet[0...10, 20...22]

    assert_empty range_set * (1...-1)
  end

  def test_that_it_convolves_range_sets
    lhs = RangeSet[0...1, 10...12]
    rhs = RangeSet[-2...1, 1...2]

    assert_equal RangeSet[-2...3, 8...14], lhs * rhs
  end

  def test_that_it_convolves_empty_range_sets
    lhs = RangeSet[]
    rhs = RangeSet[]

    assert_empty lhs * rhs
  end

  def test_that_it_convolves_empty_lhs_range_sets
    lhs = RangeSet[]
    rhs = RangeSet[-2...1, 1...2]

    assert_empty lhs * rhs
  end

  def test_that_it_convolves_empty_rhs_range_sets
    lhs = RangeSet[0...1, 10...12]
    rhs = RangeSet[]

    assert_empty lhs * rhs
  end

end
