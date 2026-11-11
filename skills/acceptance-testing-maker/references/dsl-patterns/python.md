# Python DSL Pattern: Named Parameters

Python's native support for keyword arguments makes for a very clean DSL.

## Usage Example
```python
def test_user_filters_profiles_by_headline():
    admin.create_profile(name="Alice", headline="Software Engineer at TechCorp")
    admin.create_profile(name="Bob", headline="Product Manager at StartupXYZ")

    search.by_headline_containing("Engineer")
    search.verify_visible_profiles("Alice", "Charlie")
```

## Implementation
```python
class AdminDsl:
    def __init__(self, driver):
        self.driver = driver

    def create_profile(self, name, headline, location=None, picture_url=None):
        self.driver.create_profile(
            name=name, headline=headline, location=location, picture_url=picture_url
        )

class SearchDsl:
    def __init__(self, driver):
        self.driver = driver

    def by_headline_containing(self, keyword):
        self.driver.search_by_headline(keyword)

    def verify_visible_profiles(self, *expected_names):
        actual = self.driver.get_visible_profile_names()
        assert set(actual) == set(expected_names)
```
