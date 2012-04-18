require File.join(File.dirname(__FILE__), '..', 'helper')

class TestPage < Test::Unit::TestCase
  include RikiTest

  def test_single
    pages = mocked('test_single'){Riki::Page.find_by_title('Ruby')}
    assert_equal(1, pages.size)
    page = pages.first
    
    assert_equal('Ruby', page.title)
    assert_not_empty(page.content)
    assert_equal(43551, page.id)
    assert_equal('0', page.namespace)
    
    last_mod = pages.first.last_modified
    assert_not_nil(last_mod)
    assert(1334345082 <= last_mod.to_time.to_i) # latest rev at the time of writing this test
  end

  def test_multi
    titles = ['Ruby', 'Austria', 'Vienna']
    pages = mocked('test_multi'){Riki::Page.find_by_title(titles)}
    assert_equal(titles.size, pages.size)
    
    pages.each{|page|
      titles.delete(page.title)
    }
    
    assert_equal(0, titles.size)
  end
end
