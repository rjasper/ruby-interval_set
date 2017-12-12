# IntervalSet

IntervalSet implements a set of sorted non-overlapping ranges. A range's start is always interpreted as inclusive while the end is exclusive.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rangeset'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rangeset

## Documentation

http://www.rubydoc.info/github/rjasper/rangeset

## Usage

Create a interval set:

```ruby
IntervalSet.new              # -> []
IntervalSet[]                # -> []
IntervalSet[0...1]           # -> [0...1]
IntervalSet[0...1, 2...3]    # -> [0...1, 2...3]
IntervalSet[0...1, 1...2]    # -> [0...2]

array = [0...1, 2...3]
IntervalSet[*array]          # -> [0...1, 2...3]
```

Add a range:

```ruby
IntervalSet.new << (0...1)   # -> [0...1]
IntervalSet.new.add(0...1)   # -> [0...1]

i = IntervalSet.new          # -> []
i << (0...1)              # -> [0...1]
i << (2...3)              # -> [0...1, 2...3]
i << (1...2)              # -> [0...3]
i << (-1...4)             # -> [-1...4]
```

Remove a range:

```ruby
i = IntervalSet[0...10]      # -> [0...10]
i >> (2...8)              # -> [0...2, 8...10]
i.remove(0...2)           # -> [8...10]
```

Get bounds:

```ruby
i = IntervalSet[0...1, 2...3]  # -> [0...1, 2...3]
i.min                     # -> 0
i.max                     # -> 3
i.bounds                  # -> 0...3
```

Check empty:

```ruby
IntervalSet[].empty?         # -> true

i = IntervalSet[0...1]       # -> [0...1]
i.empty?                  # -> false
i >> (0...1)              # -> []
i.empty?                  # -> true
```

Count ranges:

```ruby
i = IntervalSet[]            # -> []
i.count                   # -> 0
i << (0...1)              # -> [0...1]
i.count                   # -> 1
i << (2...3)              # -> [0...1, 2...3]
i.count                   # -> 2
i << (1...2)              # -> [0...3]
i.count                   # -> 1
```

Check inclusion:

```ruby
i = IntervalSet[0...1]       # -> [0...1]

i.include?(0)             # -> true
i.include?(0.5)           # -> true
i.include?(1)             # -> false ; a range's end is exclusive
```

Check intersection:

```ruby
i = IntervalSet[0...1]       # -> [0...1]

# Ranges only need a single common element with the interval set
i.intersect?(0...1)       # -> true
i.intersect?(0...2)       # -> true
i.intersect?(1...2)       # -> false ; the start of a range is inclusive but the end exclusive

# The same applies for interval sets
i.intersect?(IntervalSet[0...1])        # -> true
i.intersect?(IntervalSet[0...1, 2...3]) # -> true
i.intersect?(IntervalSet[2...3])        # -> false
```

Calculate union:

```ruby
IntervalSet[0...1, 2...3] | IntervalSet[1...2, 4...5] # -> [0...3, 4...5]
```

Calculate intersection:

```ruby
IntervalSet[0...2, 3...5] & IntervalSet[1...4, 5...6] # -> [1...2, 3...4]
```

Calculate difference:

```ruby
IntervalSet[0...2, 3...5] - IntervalSet[1...4, 5...6] # -> [0...1, 4...5]
```

Calculate exclusive set:

```ruby
IntervalSet[0...1] ^ IntervalSet[1...2] # -> [0...2]
IntervalSet[0...2, 4...6] ^ IntervalSet[1...5, 7...8] # -> [0...1, 2...4, 5...6, 7...8]
IntervalSet[0...1] ^ IntervalSet[0...1] # -> []
```

Compare sets:

```ruby
# A > B is true iff A is a proper superset of B
IntervalSet[0...1] > IntervalSet[0...1]          # -> false 
IntervalSet[0...2] > IntervalSet[0...1]          # -> true 
IntervalSet[0...1] > IntervalSet[1...3]          # -> false

# A >= B is true iff A is equal to B or a proper superset
IntervalSet[0...1] >= IntervalSet[0...1]         # -> true 
IntervalSet[0...2] >= IntervalSet[0...1]         # -> true 
IntervalSet[0...1] >= IntervalSet[0...1, 2...3]  # -> false
IntervalSet[0...3] >= IntervalSet[0...1, 2...3]  # -> true

# A < B is true iff A is a proper subset of B 
# Iff A < B then A > B
IntervalSet[0...1] < IntervalSet[0...2]          # -> true 
IntervalSet[1...3] < IntervalSet[0...2]          # -> false 
IntervalSet[1...3] < IntervalSet[0...2]          # -> false

# A <= B is true iff A is equal to B or a proper subset
# Iff A <= B then A >= B
IntervalSet[0...1] <= IntervalSet[0...1]         # -> true
IntervalSet[0...1] <= IntervalSet[0...2]         # -> true 
IntervalSet[0...1, 2...3] <= IntervalSet[0...1]  # -> false 
IntervalSet[0...1, 2...3] <= IntervalSet[0...3]  # -> true 

# A == B
IntervalSet[0...1] == IntervalSet[0...1]  # -> true
IntervalSet[0...1] == IntervalSet[1...2]  # -> false
```

Use in case statements:

```ruby
case 2.5
  when IntervalSet[0...2] then 'between 0 and 2'
  when IntervalSet[2...3] then 'between 2 and 3'
end
# -> "between 2 and 3"
```

Shift by a given amount:

```ruby
IntervalSet[0...1].shift(1)    # -> [1...2] 
```

Note that `shift(0)` will not be optimized since IntervalSet does not assume numbers as element type.

Buffer left and right:

```ruby
IntervalSet[1...2].buffer(1, 2) # -> [0...4]

# Negative values will shrink the ranges:
IntervalSet[0...4].buffer(-1, -2) # -> [1...2]
IntervalSet[1...2].buffer(-0.5, -0.5) # -> []
```

Convolve sets: A ∗ B = { a + b | a ∈ A ∧ b ∈ B }

```ruby
# Convolve with a range (effectively buffers the set)
IntervalSet[0...4] * (-1...2) # -> [-1...6] 

# Convolving with empty or reversed ranges result in an empty set.
IntervalSet[0...4] * (0...0)   # -> []
IntervalSet[0...4] * (1...0)   # -> []

# Convolve with a interval set
IntervalSet[0...1, 10...12] * IntervalSet[-2...1, 1...2]  # -> [-2...3, 8...14] 
```

Copy another interval set:

```ruby
a = IntervalSet[0...1]       # -> [0...1] 
b = IntervalSet[2...3]       # -> [2...3] 

a.copy(b)

a                         # -> [2...3] 
b                         # -> [2...3] 
```

Clone another interval set:

```ruby
a = IntervalSet[0...1]       # -> [0...1] 
b = a.clone               # -> [0...1] 
b << (2...3)
b                         # -> [0...1, 2...3] 
```

Use other types:

```ruby
a = Date.parse('2000-01-01') 
b = Date.parse('2000-01-02')
c = Date.parse('2000-01-03') 
 
i = IntervalSet[a...b]       # -> [2000-01-01...2000-01-02]

i << (b...c)              # -> [2000-01-01...2000-01-03] 
i.shift!(1)               # -> [2000-01-02...2000-01-04]
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
