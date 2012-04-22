require File.join(File.dirname(__FILE__), '..', 'helper')

class TestPage < Test::Unit::TestCase
  include RikiTest

  def test_single
    pages = mocked('test_single'){Riki::Page.find_by_title('Ruby')}
    assert_equal(1, pages.size)
    page = pages.first

    assert_equal('Ruby', page.title)
    assert_contains('gem', page.content)
    assert_equal(43551, page.id)
    assert_equal('0', page.namespace)
    assert_equal(DateTime.parse(Time.at(1334345082).to_s), page.last_modified)
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

  def test_normalized
    assert_equal('ISO 639-2', mocked('test_normalized'){Riki::Page.find_by_title('ISO_639-2')}.first.title)
    assert_equal('ISO 639-2', mocked('test_normalized'){Riki::Page.find_by_title('ISO 639-2')}.first.title)
  end
  
  def test_normalized_cached
    # ask for Eddie_Murphy
    # make sure asking for Eddie_Murphy results in a cache _hit_
  end
  
  # TODO Request a mixture of multiple pages, some (more than one) normalized, some not. Some redirected, some not,  
  # "Mimia" => Mimipiscis
end
