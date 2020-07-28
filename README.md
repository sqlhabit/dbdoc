[![Build Status](https://travis-ci.org/sqlhabit/dbdoc.svg?branch=master)](https://travis-ci.org/sqlhabit/dbdoc)

# dbdoc

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/dbdoc`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dbdoc'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install dbdoc

## Usage

```
dbdoc help
dbdoc init
dbdoc query
dbdoc plan
dbdoc apply
dbdoc upload
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

```
gem uninstall dbdoc && gem build dbdoc.gemspec && bundle && rake build && rake install && dbdoc help
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dbdoc.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Schema queries

### Postgres / Redshift

```sql
SELECT
  t.table_schema,
  t.table_name,
  c.column_name,
  c.data_type,
  c.ordinal_position
FROM information_schema.tables t
LEFT JOIN information_schema.columns c
  ON t.table_schema = c.table_schema
    AND t.table_name = c.table_name
WHERE
  t.table_schema NOT IN ('information_schema', 'pg_catalog')
ORDER BY 1, 2, 5
```

### MySQL

```sql
SELECT
  c.table_schema,
  c.table_name,
  c.column_name,
  c.data_type,
  c.ordinal_position
FROM information_schema.columns c
LEFT JOIN information_schema.views v
  ON v.table_schema = c.table_schema
    AND v.table_name = c.table_name
WHERE
  c.table_schema NOT IN ('sys','information_schema', 'mysql', 'performance_schema')
```
