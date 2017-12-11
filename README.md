# RangeSet

RangeSet implements a set of sorted non-overlapping ranges. A range's start is always interpreted as inclusive while the end is exclusive.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rangeset'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rangeset

## Usage

Create a range set:

```ruby
RangeSet.new              # -> []
RangeSet[]                # -> []
RangeSet[0...1]           # -> [0...1]
RangeSet[0...1, 2...3]    # -> [0...1, 2...3]
RangeSet[0...1, 1...2]    # -> [0...2]

array = [0...1, 2...3]
RangeSet[*array]          # -> [0...1, 2...3]
```

Add a range:

```ruby
RangeSet.new << (0...1)   # -> [0...1]
RangeSet.new.add(0...1)   # -> [0...1]

r = RangeSet.new          # -> []
r << (0...1)              # -> [0...1]
r << (2...3)              # -> [0...1, 2...3]
r << (1...2)              # -> [0...3]
r << (-1...4)             # -> [-1...4]
```

Remove a range:

```ruby
r = RangeSet[0...10]      # -> [0...10]
r >> (2...8)              # -> [0...2, 8...10]
r.remove(0...2)           # -> [8...10]
```

Get bounds:

```ruby
r = RangeSet[0...1, 2...3]  # -> [0...1, 2...3]
r.min                     # -> 0
r.max                     # -> 3
r.bounds                  # -> 0...3
```

Check empty:

```ruby
RangeSet[].empty?         # -> true

r = RangeSet[0...1]       # -> [0...1]
r.empty?                  # -> false
r >> (0...1)              # -> []
r.empty?                  # -> true
```

Count ranges:

```ruby
r = RangeSet[]            # -> []
r.count                   # -> 0
r << (0...1)              # -> [0...1]
r.count                   # -> 1
r << (2...3)              # -> [0...1, 2...3]
r.count                   # -> 2
r << (1...2)              # -> [0...3]
r.count                   # -> 1
```

Check inclusion:

```ruby
r = RangeSet[0...1]       # -> [0...1]

r.include?(0)             # -> true
r.include?(0.5)           # -> true
r.include?(1)             # -> false ; a range's end is exclusive

# You can also supply ranges
r.include?(0...1)         # -> true
r.include?(0...2)         # -> false ; the whole range must be included
r.include?(0...0.5)       # -> true

# .... and range sets as well
r.include?(RangeSet[0...1])               # -> true
r.include?(RangeSet[0...1, 2...3])        # -> false
r.include?(RangeSet[0...0.25, 0.75...1])  # -> true

# The other way around
RangeSet[0...1].included_by?(0...1)               # -> true 
RangeSet[0...1, 2...3].included_by?(0...1)        # -> false 
RangeSet[0...0.25, 0.75...1].included_by?(0...1)  # -> true 

```

Check intersection:

```ruby
r = RangeSet[0...1]       # -> [0...1]

# For a single element intersect? behaves exactly like include?
r.intersect?(0)           # -> true
r.intersect?(0.5)         # -> true
r.intersect?(1)           # -> false

# Ranges only need a single common element with the range set
r.intersect?(0...1)       # -> true
r.intersect?(0...2)       # -> true
r.intersect?(1...2)       # -> false ; the start of a range is inclusive but the end exclusive

# The same applies for range sets
r.intersect?(RangeSet[0...1])        # -> true
r.intersect?(RangeSet[0...1, 2...3]) # -> true
r.intersect?(RangeSet[2...3])        # -> false
```

Calculate union:

```ruby
RangeSet[0...1, 2...3] | RangeSet[1...2, 4...5] # -> [0...3, 4...5]
```

Calculate intersection:

```ruby
RangeSet[0...2, 3...5] & RangeSet[1...4, 5...6] # -> [1...2, 3...4]
```

Calculate difference:

```ruby
RangeSet[0...2, 3...5] - RangeSet[1...4, 5...6] # -> [0...1, 4...5]
```

Compare sets:

```ruby
# A > B is true iff A is a proper superset of B
RangeSet[0...2] > RangeSet[0...1]   # -> true 
RangeSet[0...2] > RangeSet[0...2]   # -> false 
RangeSet[0...2] > RangeSet[1...3]   # -> false

# A >= B is true iff A is equal to B or a proper superset
RangeSet[0...2] >= RangeSet[0...1]  # -> true 
RangeSet[0...2] >= RangeSet[0...2]  # -> true 

# A < B is true iff A is a proper subset of B 
# Iff A < B then A > B
RangeSet[0...1] < RangeSet[0...2]   # -> true 
RangeSet[1...3] < RangeSet[0...2]   # -> false 
RangeSet[1...3] < RangeSet[0...2]   # -> false

# A <= B is true iff A is equal to B or a proper subset
# Iff A <= B then A >= B
RangeSet[0...1] <= RangeSet[0...2]  # -> true 
RangeSet[0...2] <= RangeSet[0...2]  # -> true 

# A == B
RangeSet[0...1] == RangeSet[0...1]  # -> true
RangeSet[0...1] == RangeSet[1...2]  # -> false

# Compare to singleton and ranges
RangeSet[0...1].superset?(0)        # -> true 
RangeSet[0...1].superset?(1)        # -> false 
RangeSet[0...1].subset?(0)          # -> false 
RangeSet[].subset?(0)               # -> true 

RangeSet[0...3].superset?(1...2)    # -> true 
RangeSet[1...2].subset?(0...3)      # -> false 
```

Use in case statements:

```ruby
case 2.5
  when RangeSet[0...2] then 'between 0 and 2'
  when RangeSet[2...3] then 'between 2 and 3'
end
# -> "between 2 and 3"
```

Shift by a given amount:

```ruby
RangeSet[0...1].shift(1)    # -> [1...2] 
```

Note that `shift(0)` will not be optimized since RangeSet does not assume numbers as element type.

Buffer by a given range:

```ruby
RangeSet[1...2].buffer(-1...2)      # -> [0...4]

# reverse ranges will remove buffer 
RangeSet[0...4].buffer(1...-2)      # -> [1...2] 
RangeSet[1...2].buffer(0.5...-0.5)  # -> []
```

Convolve sets: A ∗ B = { a + b | a ∈ A ∧ b ∈ B }

```ruby
# Convolve with a singleton (effectively shifts the set)
RangeSet[0...1] * 1        # -> [1...2]

# Convolve with a range (effectively buffers the set)
RangeSet[0...4] * (-1...2) # -> [-1...6] 

# Convolving with reversed ranges is also possible.  However,
# the definition above doesn't apply anymore. Unfortunately,
# I didn't come up with a better definition yet :(
RangeSet[1...2] * (-1...2) # -> [0...4] 
RangeSet[0...4] * (1...-2) # -> [1...2] 

# Convolve with a range set
RangeSet[0...1, 10...12] * RangeSet[-2...1, 1...2]  # -> [-2...3, 8...14] 
```

Copy another range set:

```ruby
a = RangeSet[0...1]       # -> [0...1] 
b = RangeSet[2...3]       # -> [2...3] 

a.copy(b)

a                         # -> [2...3] 
b                         # -> [2...3] 
```

Clone another range set:

```ruby
a = RangeSet[0...1]       # -> [0...1] 
b = a.clone               # -> [0...1] 
b << (2...3)
b                         # -> [0...1, 2...3] 
```

Use other types:

```ruby
a = Date.parse('2000-01-01') 
b = Date.parse('2000-01-02')
c = Date.parse('2000-01-03') 
 
r = RangeSet[a...b]       # -> [2000-01-01...2000-01-02]

r << (b...c)              # -> [2000-01-01...2000-01-03] 
r.shift!(1)               # -> [2000-01-02...2000-01-04]
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rjasper/rangeset. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rangeset project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rjasper/rangeset/blob/master/CODE_OF_CONDUCT.md).
