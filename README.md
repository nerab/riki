# Riki

`riki` is a MediaWiki client written in Ruby.

[![Build Status](https://secure.travis-ci.org/nerab/riki.png?branch=master)](http://travis-ci.org/nerab/riki)
[![Dependency Status](https://gemnasium.com/nerab/riki.png)](https://gemnasium.com/nerab/riki)

## Installation

Add this line to your application's Gemfile:

    gem 'riki'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install riki

## Usage
### Working with Wikipedia

    # Optional - this step is only required if you are working with a non-english Wikipedia
    Riki.url = 'http://de.wikipedia.org/w/api.php'

    # find a page
    ruby = Riki::Page.find('Ruby')
    
    # query its properties
    ruby.last_modified # some date

### Working with a custom MediaWiki installation that requires authentication
    
    # Tell riki where to  to use
    Riki.url = 'http://example.com/wiki/api.php'
    Riki.username = 'jon_doe'
    Riki.password = 's3cret'

    # everything else is the same as above

## Commandline Client

`riki` comes with a simple command-line app that takes one or more titles of wikipedia pages and prints the Wikipedia page as plain text to STDOUT. Additional tools can be chained, e.g. `fmt` can be used to achieve word wrapping:

    riki "Sinatra_(software)" | fmt -w $COLUMNS

## Troubleshooting

Riki uses [RestClient](http://github.com/archiloque/rest-client) under the hood, to the simplest way to understand what goes wrong is to turn on logging for RestClient. For the bin script, the simplest way to achieve that is to set the appropriate environment variable:

    RESTCLIENT_LOG=stdout riki Ruby
    
This command will invove the `riki` script with RestClient's logging set to STDOUT.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
