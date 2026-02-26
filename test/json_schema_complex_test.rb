# frozen_string_literal: true

require 'test_helper'

class JSONSchemaComplexTest < Minitest::Test
  # Complex resource with multiple association types
  class AuthorResource
    include Alba::Resource
    
    root_key :author, :authors
    transform_keys :lower_camel
    
    attributes :id, name: String, bio: String, active: :Boolean
    attributes :follower_count, age: Integer
    
    trait :with_contact_info do
      attributes :email, :website
    end
    
    trait :with_social_media do
      nested_attribute :social_media do
        attributes :twitter, :github, :linkedin
      end
    end
  end

  class CategoryResource
    include Alba::Resource
    
    attributes :id, name: String, description: String
    attribute :slug do |category|
      category.name.downcase.gsub(' ', '-')
    end
  end

  class TagResource
    include Alba::Resource
    
    attributes :id, name: String, color: String
  end

  class CommentResource
    include Alba::Resource
    
    attributes :id, body: String, likes_count: Integer
    attributes :created_at, updated_at: String
    one :author, resource: AuthorResource
    
    # Self-referential association for threaded comments
    many :replies, resource: CommentResource
  end

  class ArticleResource
    include Alba::Resource
    
    root_key :article, :articles
    transform_keys :snake
    
    # Mixed attribute types
    attributes :id, title: String, body: String
    attributes published: :Boolean, view_count: Integer
    attributes :featured_image_url, summary: String
    
    # Computed attributes
    attribute :reading_time do |article|
      (article.body.split.length / 200.0).ceil
    end
    
    attribute :status do |article|
      if article.published
        'published'
      else
        'draft'
      end
    end
    
    # Associations
    one :author, resource: AuthorResource
    one :category, resource: CategoryResource
    many :tags, resource: TagResource
    many :comments, resource: CommentResource
    
    # Conditional associations
    many :featured_comments, 
         proc { |comments| comments.select { |c| c.likes_count > 10 } },
         resource: CommentResource
    
    # Nested attributes for metadata
    nested_attribute :metadata do
      attributes :seo_title, :seo_description, :keywords
      attribute :last_modified do |article|
        article.updated_at.iso8601
      end
      
      nested_attribute :analytics do
        attributes :page_views, :bounce_rate, :time_on_page
      end
    end
    
    # Traits for different serialization contexts
    trait :with_stats do
      attributes :view_count, :like_count, :share_count
    end
    
    trait :with_seo do
      attributes :meta_title, :meta_description, :canonical_url
    end
  end

  class BlogResource
    include Alba::Resource
    
    root_key :blog
    transform_keys :camel
    
    attributes :id, name: String, description: String
    attributes active: :Boolean, subscriber_count: Integer
    
    # Collection of articles
    many :articles, resource: ArticleResource
    many :featured_articles, 
         proc { |articles| articles.select(&:featured?) },
         resource: ArticleResource
    
    # Collection of authors
    many :authors, resource: AuthorResource
    
    # Nested configuration
    nested_attribute :settings do
      attributes :theme, :language, :timezone
      attribute :features do |blog|
        {
          comments_enabled: blog.comments_enabled,
          social_sharing: blog.social_sharing,
          newsletter: blog.newsletter_enabled
        }
      end
    end
    
    # Array types
    attributes supported_languages: :ArrayOfString
    attributes monthly_views: :ArrayOfInteger
  end

  class UserProfileResource
    include Alba::Resource
    
    # Complex nested structure
    nested_attribute :personal_info do
      attributes :first_name, :last_name, :date_of_birth
      
      nested_attribute :address do
        attributes :street, :city, :state, :country, :zip_code
        
        nested_attribute :coordinates do
          attributes :latitude, :longitude
        end
      end
    end
    
    nested_attribute :preferences do
      attributes :theme, :language, notifications_enabled: :Boolean
      attributes :newsletter_frequency, :privacy_level
    end
    
    # Conditional attributes based on params
    attributes :email, if: proc { |user| params[:include_private_info] }
    attributes :phone, if: proc { |user| params[:include_private_info] }
    
    # Association with conditions
    many :public_articles, 
         proc { |articles| articles.select(&:published?) },
         resource: ArticleResource,
         if: proc { |user| params[:include_articles] }
  end

  # Test complex resource schema generation
  def test_complex_article_resource_schema
    schema = Alba::JSONSchema.generate(ArticleResource)
    
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('article')
    
    article_props = schema['properties']['article']['properties']
    
    # Check basic attributes
    assert_equal 'string', article_props['id']['type']
    assert_equal 'string', article_props['title']['type']
    assert_equal 'boolean', article_props['published']['type']
    assert_equal 'integer', article_props['view_count']['type']
    
    # Check computed attributes
    assert_equal 'Computed attribute', article_props['reading_time']['description']
    assert_equal 'Computed attribute', article_props['status']['description']
    
    # Check associations
    assert_equal '#/$defs/Author', article_props['author']['$ref']
    assert_equal 'array', article_props['tags']['type']
    assert_equal '#/$defs/Tag', article_props['tags']['items']['$ref']
    
    # Check nested attributes
    assert_equal 'object', article_props['metadata']['type']
    metadata_props = article_props['metadata']['properties']
    assert metadata_props.key?('seo_title')
    assert_equal 'object', metadata_props['analytics']['type']
    
    # Check definitions are included
    assert schema.key?('$defs')
    assert schema['$defs'].key?('Author')
    assert schema['$defs'].key?('Tag')
    assert schema['$defs'].key?('Category')
    assert schema['$defs'].key?('Comment')
  end

  def test_blog_resource_with_array_types
    Alba.inflector = :active_support
    
    schema = Alba::JSONSchema.generate(BlogResource)
    
    blog_props = schema['properties']['Blog']['properties']
    
    # Check array type attributes
    supported_langs = blog_props['SupportedLanguages']
    assert_equal 'array', supported_langs['type']
    assert_equal 'string', supported_langs['items']['type']
    
    monthly_views = blog_props['MonthlyViews']
    assert_equal 'array', monthly_views['type']
    assert_equal 'integer', monthly_views['items']['type']
    
    # Check CamelCase transformation
    assert blog_props.key?('SubscriberCount')
    refute blog_props.key?('subscriber_count')
  ensure
    Alba.inflector = nil
  end

  def test_resource_with_traits
    Alba.inflector = :active_support
    
    # Test with single trait
    schema_with_stats = Alba::JSONSchema.generate(ArticleResource, traits: [:with_stats])
    article_props = schema_with_stats['properties']['article']['properties']
    
    assert article_props.key?('view_count')
    assert article_props.key?('like_count')
    assert article_props.key?('share_count')
    
    # Test with multiple traits
    schema_with_multiple = Alba::JSONSchema.generate(
      ArticleResource, 
      traits: [:with_stats, :with_seo]
    )
    article_props_multi = schema_with_multiple['properties']['article']['properties']
    
    assert article_props_multi.key?('view_count')
    assert article_props_multi.key?('meta_title')
    assert article_props_multi.key?('canonical_url')
  ensure
    Alba.inflector = nil
  end

  def test_author_resource_with_traits_and_transformation
    Alba.inflector = :active_support
    
    schema = Alba::JSONSchema.generate(
      AuthorResource, 
      traits: [:with_contact_info, :with_social_media]
    )
    
    author_props = schema['properties']['author']['properties']
    
    # Check camelCase transformation
    assert author_props.key?('followerCount')
    refute author_props.key?('follower_count')
    
    # Check trait attributes
    assert author_props.key?('email')
    assert author_props.key?('website')
    
    # Check nested trait attributes
    assert_equal 'object', author_props['socialMedia']['type']
    social_props = author_props['socialMedia']['properties']
    assert social_props.key?('twitter')
    assert social_props.key?('github')
  ensure
    Alba.inflector = nil
  end

  def test_deeply_nested_user_profile_resource
    schema = Alba::JSONSchema.generate(UserProfileResource)
    
    props = schema['properties']
    
    # Check top-level nested attributes
    assert_equal 'object', props['personal_info']['type']
    assert_equal 'object', props['preferences']['type']
    
    # Check deeply nested structure
    personal_info = props['personal_info']['properties']
    assert personal_info.key?('first_name')
    assert_equal 'object', personal_info['address']['type']
    
    address_props = personal_info['address']['properties']
    assert address_props.key?('street')
    assert_equal 'object', address_props['coordinates']['type']
    
    coords_props = address_props['coordinates']['properties']
    assert coords_props.key?('latitude')
    assert coords_props.key?('longitude')
    
    # Check preferences
    prefs_props = props['preferences']['properties']
    assert_equal 'boolean', prefs_props['notifications_enabled']['type']
  end

  def test_self_referential_comment_resource
    schema = Alba::JSONSchema.generate(CommentResource)
    
    props = schema['properties']
    
    # Check basic attributes
    assert_equal 'string', props['body']['type']
    assert_equal 'integer', props['likes_count']['type']
    
    # Check author association
    assert_equal '#/$defs/Author', props['author']['$ref']
    
    # Check self-referential replies
    assert_equal 'array', props['replies']['type']
    assert_equal '#/$defs/Comment', props['replies']['items']['$ref']
    
    # Ensure Comment definition exists
    assert schema.key?('$defs')
    assert schema['$defs'].key?('Comment')
  end

  def test_schema_with_custom_title_and_description
    schema = Alba::JSONSchema.generate(
      ArticleResource,
      title: 'Article API Schema',
      description: 'Schema for article resources in the blog API'
    )
    
    assert_equal 'Article API Schema', schema['title']
    assert_equal 'Schema for article resources in the blog API', schema['description']
  end

  def test_schema_without_root_key
    simple_resource = Class.new do
      include Alba::Resource
      
      attributes :id, :name, :email
    end
    
    schema = Alba::JSONSchema.generate(simple_resource)
    
    # Should not have root key wrapper
    refute schema['properties'].key?('article')
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('name')
    assert schema['properties'].key?('email')
  end

  def test_resource_with_conditional_associations
    schema = Alba::JSONSchema.generate(ArticleResource)
    
    article_props = schema['properties']['article']['properties']
    
    # Featured comments should be included as they're defined in the resource
    assert_equal 'array', article_props['featured_comments']['type']
    assert_equal '#/$defs/Comment', article_props['featured_comments']['items']['$ref']
  end

  def test_collection_key_resource
    collection_resource = Class.new do
      include Alba::Resource
      
      collection_key :id
      attributes :id, :name, :value
    end
    
    schema = Alba::JSONSchema.generate(collection_resource)
    
    # Collection key doesn't affect individual resource schema
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('name')
    assert schema['properties'].key?('value')
  end

  def test_resource_with_custom_inflector
    custom_inflector = Module.new do
      def self.camelize(string)
        string.split('_').map(&:capitalize).join
      end
      
      def self.camelize_lower(string)
        parts = string.split('_')
        parts[0] + parts[1..].map(&:capitalize).join
      end
      
      def self.dasherize(string)
        string.tr('_', '-')
      end
      
      def self.classify(string)
        camelize(string)
      end
      
      def self.underscore(string)
        string.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .downcase
      end
    end
    
    Alba.inflector = custom_inflector
    
    custom_resource = Class.new do
      include Alba::Resource
      
      transform_keys :lower_camel
      attributes :id, :first_name, :last_name
    end
    
    schema = Alba::JSONSchema.generate(custom_resource)
    
    assert schema['properties'].key?('firstName')
    assert schema['properties'].key?('lastName')
  ensure
    Alba.inflector = nil
  end

  def test_resource_with_on_error_handling
    error_resource = Class.new do
      include Alba::Resource
      
      attributes :id, :name, :problematic_field
      on_error :ignore
    end
    
    # Error handling doesn't affect schema generation
    schema = Alba::JSONSchema.generate(error_resource)
    
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('problematic_field')
  end

  def test_resource_with_layout
    layout_resource = Class.new do
      include Alba::Resource
      
      attributes :id, :content
      layout inline: proc { { wrapper: serializable_hash } }
    end
    
    # Layout doesn't affect the core schema
    schema = Alba::JSONSchema.generate(layout_resource)
    
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('content')
  end

  def test_resource_inheritance
    base_resource = Class.new do
      include Alba::Resource
      
      attributes :id, :created_at, :updated_at
    end
    
    extended_resource = Class.new(base_resource) do
      attributes :name, :description
      attribute :display_name do |obj|
        obj.name.upcase
      end
    end
    
    schema = Alba::JSONSchema.generate(extended_resource)
    
    # Should include both base and extended attributes
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('created_at')
    assert schema['properties'].key?('name')
    assert schema['properties'].key?('description')
    assert schema['properties'].key?('display_name')
  end
end