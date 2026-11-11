# Ruby DSL Pattern: RSpec Style

Ruby's `instance_eval` enables very clean, block-based DSLs.

## Usage Example

```ruby
RSpec.describe "Profile search" do
  it "filters profiles by headline keyword" do
    given do
      profile named: "Alice", headline: "Software Engineer at TechCorp"
      profile named: "Bob", headline: "Product Manager at StartupXYZ"
    end

    when_user do
      searches_for_headline_containing "Engineer"
    end

    then_user do
      should_see_profiles "Alice", "Charlie"
    end
  end
end
```

## Implementation

```ruby
module AcceptanceDsl
  def given(&block)
    @given_scope = GivenScope.new(driver)
    @given_scope.instance_eval(&block)
  end

  def when_user(&block)
    @when_scope = WhenScope.new(driver)
    @when_scope.instance_eval(&block)
  end

  def then_user(&block)
    @then_scope = ThenScope.new(driver)
    @then_scope.instance_eval(&block)
  end

  def driver
    @driver ||= DriverRegistry.get(ENV['DRIVER'] || 'DOMAIN_IN_MEMORY')
  end
end

class GivenScope
  def initialize(driver)
    @driver = driver
  end

  def profile(name:, headline:, location: nil)
    @driver.create_profile(name, headline, location)
  end
end

class WhenScope
  def initialize(driver)
    @driver = driver
  end

  def searches_for_headline_containing(keyword)
    @driver.search_by_headline(keyword)
  end
end

class ThenScope
  def initialize(driver)
    @driver = driver
  end

  def should_see_profiles(*expected_names)
    actual = @driver.get_visible_profile_names
    expect(actual).to match_array(expected_names)
  end
end

RSpec.configure do |config|
  config.include AcceptanceDsl
end
```
