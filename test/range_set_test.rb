require './test/test_helper'

class RangeSetTest < Minitest::Test

  def test_that_it_initializes
    assert RangeSet.new
  end

  def test_that_empty_converts_to_string
    assert_equal '[]', RangeSet.new.to_s
  end

  def test_that_it_converts_to_string
    assert_equal '[1..2, 3..4]', RangeSet.new.add(1..2).add(3..4).to_s
  end

  def test_that_it_is_empty
    assert_empty RangeSet.new
  end

  def test_that_it_is_not_empty
    assert !RangeSet.new.add(0..1).empty?
  end

  def test_that_it_copies_empty
    original = RangeSet.new
    copy = RangeSet.new

    copy = copy.copy(original)

    assert_empty copy
    assert copy != original
  end

  def test_that_it_copies_non_empty
    original = RangeSet.new << (0..1)
    copy = RangeSet.new

    copy.copy(original)

    assert_equal [0..1], copy.to_a
    assert copy != original
  end

  def test_that_it_clears_data_on_copy
    original = RangeSet.new << (0..1)
    copy = RangeSet.new << (2..3)

    copy.copy(original)

    assert_equal [0..1], copy.to_a
    assert copy != original
  end

  def test_that_it_clones_empty
    original = RangeSet.new

    clone = original.clone

    assert_empty clone
    assert clone != original
  end

  def test_that_it_clones_non_empty
    original = RangeSet.new << (0..1)

    clone = original.clone

    assert_equal [0..1], clone.to_a
    assert clone != original
  end

  def test_that_range_overlaps
    range_set = RangeSet.new << (1..2)

    assert range_set.overlapped_by?(1..2) # both exact
    assert range_set.overlapped_by?(0..2) # right exact
    assert range_set.overlapped_by?(1..3) # left exact
    assert range_set.overlapped_by?(0..3) # both extra
  end

  def test_that_range_does_not_overlap
    range_set = RangeSet.new << (1..2)

    assert !range_set.overlapped_by?(0..1) # on left
    assert !range_set.overlapped_by?(2..3) # on right
    assert !range_set.overlapped_by?(1..1.5) # not right
    assert !range_set.overlapped_by?(1.5..2) # not left
  end

  def test_that_numeric_is_included
    range_set = RangeSet.new << (1..2)

    assert range_set.include?(1)
    assert range_set.include?(1.5)
  end

  def test_that_numeric_is_not_included
    range_set = RangeSet.new << (1..2)

    assert !range_set.include?(0)
    assert !range_set.include?(2)
    assert !range_set.include?(3)
  end

  def test_that_empty_does_not_include_range
    assert !RangeSet.new.include?(0..1)
  end

  def test_that_it_includes_range
    range_set = RangeSet.new << (0..1) << (2..3)

    assert range_set.include?(0..1)
    assert range_set.include?(0.5..1)
    assert range_set.include?(0..0.5)
    assert range_set.include?(0.25..0.75)
    assert range_set.include?(2..3)
  end

  def test_that_it_not_includes_range
    range_set = RangeSet.new << (0..1) << (2..3)

    assert !range_set.include?(-2..-1)
    assert !range_set.include?(-1..0)
    assert !range_set.include?(-1..0.5)
    assert !range_set.include?(-1..1)
    assert !range_set.include?(-1..1.5)
    assert !range_set.include?(-1..2)
    assert !range_set.include?(1..4)
    assert !range_set.include?(1.5..4)
    assert !range_set.include?(2..4)
    assert !range_set.include?(2.5..4)
    assert !range_set.include?(3..4)
    assert !range_set.include?(5..6)
    assert !range_set.include?(0..3)
  end

  def test_that_empty_includes_empty_range_set
    assert RangeSet.new.include?(RangeSet.new)
  end

  def test_that_empty_does_not_include_range_set
    assert !RangeSet.new.include?(RangeSet.new << (0..1))
  end

  def test_that_range_set_includes_empty
    assert RangeSet.new.add(0..1).include?(RangeSet.new)
  end

  def test_that_range_set_is_included
    range_set = RangeSet.new << (1..2) << (3..4)

    assert range_set.include?(RangeSet.new << (1..2))
    assert range_set.include?(RangeSet.new << (3..4))
    assert range_set.include?(RangeSet.new << (1..2) << (3..4))
  end

  def test_that_range_set_is_not_included
    range_set = RangeSet.new << (1..2) << (3..4)

    assert !range_set.include?(RangeSet.new << (0..3))
    assert !range_set.include?(RangeSet.new << (1..2) << (3..4) << (5..6))
  end

  def test_that_it_intersects_range
    range_set = RangeSet.new << (0..1) << (2..3)

    assert range_set.intersect?(0..1)
    assert range_set.intersect?(0.5..1)
    assert range_set.intersect?(0..0.5)
    assert range_set.intersect?(0.25..0.75)
    assert range_set.intersect?(2..3)
    assert range_set.intersect?(-1..0.5)
    assert range_set.intersect?(-1..1)
    assert range_set.intersect?(-1..1.5)
    assert range_set.intersect?(-1..2)
    assert range_set.intersect?(1..4)
    assert range_set.intersect?(1.5..4)
    assert range_set.intersect?(2..4)
    assert range_set.intersect?(2.5..4)
    assert range_set.intersect?(0..3)
  end

  def test_that_it_not_intersects_range
    range_set = RangeSet.new << (0..1) << (2..3)

    assert !range_set.intersect?(-2..-1)
    assert !range_set.intersect?(-1..0)
    assert !range_set.intersect?(3..4)
    assert !range_set.intersect?(5..6)
  end

  def test_that_range_is_within_bounds
    range_set = RangeSet.new << (1..2)

    assert range_set.within_bounds?(1..2) # both exact
    assert range_set.within_bounds?(0..2) # right exact
    assert range_set.within_bounds?(1..3) # left exact
    assert range_set.within_bounds?(0..3) # both extra
    assert range_set.within_bounds?(1..1.5) # not right
    assert range_set.within_bounds?(1.5..2) # not left
  end

  def test_that_range_is_not_within_bounds
    range_set = RangeSet.new << (1..2)

    assert !range_set.within_bounds?(0..1) # on left
    assert !range_set.within_bounds?(2..3) # on right
  end

  def test_that_empty_has_no_min
    assert_nil RangeSet.new.min
  end

  def test_that_min_equals_range_min
    range_set = RangeSet.new << (1..2)

    assert_equal 1, range_set.min
  end

  def test_that_max_equals_range_max
    range_set = RangeSet.new << (1..2)

    assert_equal 2, range_set.max
  end

  def test_ignore_empty_range
    range_set = RangeSet.new << (1..1)

    assert range_set.empty?
  end

  def test_ignore_reversed_range
    range_set = RangeSet.new << (2..1)

    assert range_set.empty?
  end

  def test_that_empty_has_no_max
    assert_nil RangeSet.new.max
  end

  def test_that_it_adds_covering_range
    range_set = RangeSet.new << (1..2)

    assert_equal 1, range_set.count

    range_set << (0..3)

    assert_equal 1, range_set.count
  end

  def test_that_it_adds_range_not_within_bounds
    range_set = RangeSet.new << (1..2)

    assert_equal 1, range_set.count

    range_set << (3..4)

    assert_equal 2, range_set.count
  end

  def test_that_included_ranges_are_ignored
    range_set = RangeSet.new << (1..2) << (3..4) << (5..6)

    assert_equal 3, range_set.count

    range_set << (3..4)

    assert_equal 3, range_set.count
  end

  def test_that_it_adds_ranges
    range_set = RangeSet.new

    range_set << (0..1)

    assert_equal [0..1], range_set.to_a
  end

  def test_that_it_adds_ranges_left
    range_set = RangeSet.new << (0..1)

    range_set << (-2..-1)

    assert_equal [-2..-1, 0..1], range_set.to_a
  end

  def test_that_it_adds_ranges_right
    range_set = RangeSet.new << (-2..-1)

    range_set << (0..1)

    assert_equal [-2..-1, 0..1], range_set.to_a
  end

  def test_that_it_adds_ranges_left_tight
    range_set = RangeSet.new << (0..1)

    range_set << (-2..0)

    assert_equal [-2..1], range_set.to_a
  end

  def test_that_it_adds_ranges_right_tight
    range_set = RangeSet.new << (-2..0)

    range_set << (0..1)

    assert_equal [-2..1], range_set.to_a
  end

  def test_that_it_adds_left_overlapping
    range_set = RangeSet.new << (-1..1)

    range_set << (-2..0)

    assert_equal [-2..1], range_set.to_a
  end

  def test_that_it_adds_right_overlapping
    range_set = RangeSet.new << (-2..0)

    range_set<< (-1..1)

    assert_equal [-2..1], range_set.to_a
  end

  def test_that_it_adds_range_set
    range_set1 = RangeSet.new << (0..1) << (4..5)
    range_set2 = RangeSet.new << (2..3) << (6..7)

    range_set1 << range_set2

    assert_equal [0..1, 2..3, 4..5, 6..7], range_set1.to_a
  end

  def test_that_it_adds_empty_range_set
    range_set1 = RangeSet.new << (0..1) << (4..5)
    range_set2 = RangeSet.new

    range_set1 << range_set2

    assert_equal [0..1, 4..5], range_set1.to_a
  end

  def test_that_it_can_add_itself
    range_set = RangeSet.new << (0..1) << (4..5)

    range_set << range_set

    assert_equal [0..1, 4..5], range_set.to_a
  end

  def test_that_it_removes_from_empty
    range_set = RangeSet.new >> (1..2)

    assert_empty range_set
  end

  def test_that_it_removes_left
    range_set = RangeSet.new << (0..1) >> (-2..-1)

    assert_equal [0..1], range_set.to_a
  end

  def test_that_it_removes_right
    range_set = RangeSet.new << (0..1) >> (2..3)

    assert_equal [0..1], range_set.to_a
  end

  def test_that_it_removes_tight_left
    range_set = RangeSet.new << (0..1)

    range_set >> (-2..0)

    assert_equal [0..1], range_set.to_a
  end

  def test_that_it_removes_tight_right
    range_set = RangeSet.new << (0..1)

    range_set >> (1..3)

    assert_equal [0..1], range_set.to_a
  end

  def test_that_it_removes_left_overlap
    range_set = RangeSet.new << (0..1)

    range_set >> (-2..0.5)

    assert_equal [0.5..1], range_set.to_a
  end

  def test_that_it_removes_right_overlap
    range_set = RangeSet.new << (0..1)

    range_set >> (0.5..3)

    assert_equal [0..0.5], range_set.to_a
  end

  def test_that_it_removes_inbetween
    range_set = RangeSet.new << (0..1)

    range_set >> (0.25..0.75)

    assert_equal [0..0.25, 0.75..1], range_set.to_a
  end

  def test_that_it_removes_entire_set
    range_set = RangeSet.new << (0..1)

    range_set >> (-1..2)

    assert_empty range_set
  end

  def test_that_it_removes_bounds
    range_set = RangeSet.new << (0..1)

    range_set >> (0..1)

    assert_empty range_set
  end

  def test_that_it_removes_range_set
    range_set1 = RangeSet.new << (0..2) << (3..5)
    range_set2 = RangeSet.new << (1..4) << (6..7)

    range_set1 >> range_set2

    assert_equal [0..1, 4..5], range_set1.to_a
  end

  def test_that_it_removes_itself
    range_set = RangeSet.new << (0..1) << (4..5)

    range_set >> range_set

    assert_empty range_set
  end

  def test_that_it_clears
    range_set = RangeSet.new << (1..2)

    assert !range_set.empty?

    range_set.clear

    assert range_set.empty?
  end

  def test_that_it_intersects_empty
    assert_empty RangeSet.new.intersect(0..1)
  end

  def test_that_it_intersects_left
    range_set = RangeSet.new << (0..1)

    assert_empty range_set.intersect(-2..-1)
  end

  def test_that_it_intersects_right
    range_set = RangeSet.new << (0..1)

    assert_empty range_set.intersect(2..3)
  end

  def test_that_it_intersects_tight_left
    range_set = RangeSet.new << (0..1)

    assert_empty range_set.intersect(-2..0)
  end

  def test_that_it_intersects_tight_right
    range_set = RangeSet.new << (0..1)

    assert_empty range_set.intersect(1..3)
  end

  def test_that_it_intersects_left_overlap
    range_set = RangeSet.new << (0..1)

    assert_equal [0..0.5], range_set.intersect(-2..0.5).to_a
  end

  def test_that_it_intersects_right_overlap
    range_set = RangeSet.new << (0..1)

    assert_equal [0.5..1], range_set.intersect(0.5..3).to_a
  end

  def test_that_it_intersects_inbetween
    range_set = RangeSet.new << (0..1)

    assert_equal [0.25..0.75], range_set.intersect(0.25..0.75).to_a
  end

  def test_that_it_intersects_entire_set
    range_set = RangeSet.new << (0..1)

    assert_equal [0..1], range_set.intersect(-1..2).to_a
  end

  def test_that_it_intersects_bounds
    range_set = RangeSet.new << (0..1)

    assert_equal [0..1], range_set.intersect(0..1).to_a
  end

  def test_that_it_intersects_range_set
    range_set1 = RangeSet.new << (0..2) << (3..5)
    range_set2 = RangeSet.new << (1..4) << (6..7)

    assert_equal [1..2, 3..4], range_set1.intersect(range_set2).to_a
  end

  def test_that_it_intersects_itself
    range_set = RangeSet.new << (0..1) << (2..3)

    assert_equal [0..1, 2..3], range_set.intersect(range_set).to_a
  end

  def test_that_it_unions_empty
    lhs = RangeSet.new
    rhs = RangeSet.new

    assert_empty lhs.union(rhs).to_a
  end

  def test_that_it_unions_empty_lhs
    lhs = RangeSet.new
    rhs = RangeSet.new << (0..1)

    assert_equal [0..1], lhs.union(rhs).to_a
  end

  def test_that_it_unions_empty_rhs
    lhs = RangeSet.new << (0..1)
    rhs = RangeSet.new

    assert_equal [0..1], lhs.union(rhs).to_a
  end

  def test_that_it_unions_left
    assert_equal [-2..-1, 0..1], RangeSet.new.add(0..1).union(-2..-1).to_a
  end

  def test_that_it_unions_right
    assert_equal [0..1, 2..3], RangeSet.new.add(0..1).union(2..3).to_a
  end

  def test_that_it_unions_tight_left
    assert_equal [-2..1], RangeSet.new.add(0..1).union(-2..0).to_a
  end

  def test_that_it_unions_tight_right
    assert_equal [0..3], RangeSet.new.add(0..1).union(1..3).to_a
  end

  def test_that_it_unions_left_overlap
    assert_equal [-2..1], RangeSet.new.add(0..1).union(-2..0.5).to_a
  end

  def test_that_it_unions_right_overlap
    assert_equal [0..3], RangeSet.new.add(0..1).union(0.5..3).to_a
  end

  def test_that_it_unions_inbetween
    assert_equal [0..1], RangeSet.new.add(0..1).union(0.25..0.75).to_a
  end

  def test_that_it_unions_entire_set
    assert_equal [-1..2], RangeSet.new.add(0..1).union(-1..2).to_a
  end

  def test_that_it_unions_bounds
    assert_equal [0..1], RangeSet.new.add(0..1).union(0..1).to_a
  end

  def test_that_it_unions_range_set
    lhs = RangeSet.new << (0..1) << (4..5)
    rhs = RangeSet.new << (2..3) << (6..7)

    assert_equal [0..1, 2..3, 4..5, 6..7], lhs.union(rhs).to_a
  end

  def test_that_it_unions_itself
    range_set = RangeSet.new << (0..1)

    assert_equal [0..1], range_set.union(range_set).to_a
  end

  def test_that_it_differences_empty
    lhs = RangeSet.new
    rhs = RangeSet.new

    assert_empty lhs.difference(rhs)
  end

  def test_that_it_differences_empty_lhs
    lhs = RangeSet.new
    rhs = RangeSet.new << (0..1)

    assert_empty lhs.difference(rhs)
  end

  def test_that_it_differences_empty_rhs
    lhs = RangeSet.new << (0..1)
    rhs = RangeSet.new

    assert_equal [0..1], lhs.difference(rhs).to_a
  end

  def test_that_it_differences_left
    assert_equal [0..1], RangeSet.new.add(0..1).difference(-2..-1).to_a
  end

  def test_that_it_differences_right
    assert_equal [0..1], RangeSet.new.add(0..1).difference(2..3).to_a
  end

  def test_that_it_differences_tight_left
    assert_equal [0..1], RangeSet.new.add(0..1).difference(-2..0).to_a
  end

  def test_that_it_differences_tight_right
    assert_equal [0..1], RangeSet.new.add(0..1).difference(1..3).to_a
  end

  def test_that_it_differences_left_overlap
    assert_equal [0.5..1], RangeSet.new.add(0..1).difference(-2..0.5).to_a
  end

  def test_that_it_differences_right_overlap
    assert_equal [0..0.5], RangeSet.new.add(0..1).difference(0.5..3).to_a
  end

  def test_that_it_differences_inbetween
    assert_equal [0..0.25, 0.75..1], RangeSet.new.add(0..1).difference(0.25..0.75).to_a
  end

  def test_that_it_differences_entire_set
    assert_empty RangeSet.new.add(0..1).difference(-1..2)
  end

  def test_that_it_differences_bounds
    assert_empty RangeSet.new.add(0..1).difference(0..1)
  end

  def test_that_it_differences_range_set
    lhs = RangeSet.new << (0..2) << (3..5)
    rhs = RangeSet.new << (1..4) << (6..7)

    assert_equal [0..1, 4..5], lhs.difference(rhs).to_a
  end

  def test_that_it_differences_itself
    range_set = RangeSet.new << (0..1)

    assert_empty range_set.difference(range_set)
  end

  def test_that_it_convolves_numeric
    range_set = RangeSet.new << (0..1) << (2..3)

    assert_equal [1..2, 3..4], range_set.convolve!(1).to_a
  end

  def test_that_it_shifts_numeric
    range_set = RangeSet.new << (0..1) << (2..3)

    assert_equal [1..2, 3..4], range_set.shift(1).to_a
  end

  def test_that_it_convolves_range
    range_set = RangeSet.new << (0..1) << (4..5) << (9..10)

    assert_equal [-1..7, 8..12], range_set.convolve!(-1..2).to_a
  end

  def test_that_it_buffers_range
    range_set = RangeSet.new << (0..1) << (4..5) << (9..10)

    assert_equal [-1..7, 8..12], range_set.buffer!(-1..2).to_a
  end

  def test_that_it_convolves_reversed_range
    range_set = RangeSet.new << (0..10) << (20..22)

    assert_equal [1..9], range_set.convolve!(1..-1).to_a
  end

  def test_that_it_convolves_range_sets
    lhs = RangeSet.new << (0..1) << (10..12)
    rhs = RangeSet.new << (-2..1) << (1..2)

    assert_equal [-2..3, 8..14], lhs.convolve!(rhs).to_a
  end

  def test_that_it_convolves_empty_range_sets
    lhs = RangeSet.new
    rhs = RangeSet.new

    assert_empty lhs.convolve!(rhs)
  end

  def test_that_it_convolves_empty_lhs_range_sets
    lhs = RangeSet.new
    rhs = RangeSet.new << (-2..1) << (1..2)

    assert_empty lhs.convolve!(rhs)
  end

  def test_that_it_convolves_empty_rhs_range_sets
    lhs = RangeSet.new << (0..1) << (10..12)
    rhs = RangeSet.new

    assert_empty lhs.convolve!(rhs)
  end

end
