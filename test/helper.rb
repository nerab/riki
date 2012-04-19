require 'test/unit'
require 'vcr'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'riki'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

module RikiTest
  def mocked(cassette, &block)
    VCR.use_cassette("#{self.class.name}_#{cassette}", :record => :new_episodes) do
      block.call
    end
  end
end

class Test::Unit::TestCase
  def assert_contains(expected, actual)
    assert(actual =~ /#{expected}/, "Did not contain #{expected}: #{actual}")
  end
end
