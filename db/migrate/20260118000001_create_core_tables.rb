# frozen_string_literal: true

class CreateCoreTables < ActiveRecord::Migration[8.1]
  def change
    # ============================================
    # Users
    # ============================================
    create_table :users, id: :string do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :encrypted_password, null: false
      t.string :api_key_digest
      t.string :role, default: 'user', null: false
      t.json :settings, default: {}
      t.datetime :last_sign_in_at

      # Devise fields
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :api_key_digest, unique: true
    add_index :users, :reset_password_token, unique: true

    # ============================================
    # Organizations
    # ============================================
    create_table :organizations, id: :string do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.json :settings, default: {}

      t.timestamps
    end

    add_index :organizations, :slug, unique: true

    # ============================================
    # Organization Memberships
    # ============================================
    create_table :organization_memberships, id: :string do |t|
      t.string :organization_id, null: false
      t.string :user_id, null: false
      t.string :role, default: 'member', null: false

      t.timestamps
    end

    add_index :organization_memberships, :organization_id
    add_index :organization_memberships, :user_id
    add_index :organization_memberships, [:organization_id, :user_id], unique: true
    add_foreign_key :organization_memberships, :organizations
    add_foreign_key :organization_memberships, :users

    # ============================================
    # Namespaces
    # ============================================
    create_table :namespaces, id: :string do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :visibility, default: 'private', null: false
      t.string :owner_type, null: false
      t.string :owner_id, null: false
      t.json :settings, default: {}

      t.timestamps
    end

    add_index :namespaces, :slug, unique: true
    add_index :namespaces, [:owner_type, :owner_id]
    add_index :namespaces, :visibility

    # ============================================
    # Type Definitions
    # ============================================
    create_table :type_definitions, id: :string do |t|
      t.string :namespace_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :category, null: false
      t.string :current_version_id
      t.boolean :deprecated, default: false
      t.text :deprecation_message
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :type_definitions, :namespace_id
    add_index :type_definitions, [:namespace_id, :slug], unique: true
    add_index :type_definitions, :category
    add_index :type_definitions, :deprecated
    add_foreign_key :type_definitions, :namespaces

    # ============================================
    # Type Versions
    # ============================================
    create_table :type_versions, id: :string do |t|
      t.string :type_definition_id, null: false
      t.string :version, null: false
      t.integer :version_major, null: false
      t.integer :version_minor, null: false
      t.integer :version_patch, null: false
      t.json :content, null: false
      t.string :content_hash, null: false
      t.string :git_sha
      t.string :git_path
      t.text :changelog
      t.datetime :published_at
      t.string :published_by_id

      t.timestamps
    end

    add_index :type_versions, :type_definition_id
    add_index :type_versions, [:type_definition_id, :version], unique: true
    add_index :type_versions, :git_sha
    add_index :type_versions, :content_hash
    add_index :type_versions, [:type_definition_id, :version_major, :version_minor, :version_patch],
              name: 'idx_type_versions_semver'
    add_foreign_key :type_versions, :type_definitions
    add_foreign_key :type_versions, :users, column: :published_by_id

    # Add foreign key for current_version_id after type_versions exists
    add_foreign_key :type_definitions, :type_versions, column: :current_version_id

    # ============================================
    # Data Shapes
    # ============================================
    create_table :data_shapes, id: :string do |t|
      t.string :namespace_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.string :format, null: false
      t.text :description
      t.string :current_version_id
      t.boolean :deprecated, default: false
      t.text :deprecation_message
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :data_shapes, :namespace_id
    add_index :data_shapes, [:namespace_id, :slug], unique: true
    add_index :data_shapes, :format
    add_index :data_shapes, :deprecated
    add_foreign_key :data_shapes, :namespaces

    # ============================================
    # Shape Versions
    # ============================================
    create_table :shape_versions, id: :string do |t|
      t.string :data_shape_id, null: false
      t.string :version, null: false
      t.integer :version_major, null: false
      t.integer :version_minor, null: false
      t.integer :version_patch, null: false
      t.json :content, null: false
      t.text :raw_content
      t.string :content_hash, null: false
      t.string :git_sha
      t.string :git_path
      t.text :changelog
      t.datetime :published_at
      t.string :published_by_id

      t.timestamps
    end

    add_index :shape_versions, :data_shape_id
    add_index :shape_versions, [:data_shape_id, :version], unique: true
    add_index :shape_versions, :git_sha
    add_index :shape_versions, :content_hash
    add_index :shape_versions, [:data_shape_id, :version_major, :version_minor, :version_patch],
              name: 'idx_shape_versions_semver'
    add_foreign_key :shape_versions, :data_shapes
    add_foreign_key :shape_versions, :users, column: :published_by_id

    # Add foreign key for current_version_id
    add_foreign_key :data_shapes, :shape_versions, column: :current_version_id

    # ============================================
    # API Specs
    # ============================================
    create_table :api_specs, id: :string do |t|
      t.string :namespace_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.string :spec_type, null: false
      t.text :description
      t.string :current_version_id
      t.boolean :deprecated, default: false
      t.text :deprecation_message
      t.string :base_url
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :api_specs, :namespace_id
    add_index :api_specs, [:namespace_id, :slug], unique: true
    add_index :api_specs, :spec_type
    add_index :api_specs, :deprecated
    add_foreign_key :api_specs, :namespaces

    # ============================================
    # API Spec Versions
    # ============================================
    create_table :api_spec_versions, id: :string do |t|
      t.string :api_spec_id, null: false
      t.string :version, null: false
      t.integer :version_major, null: false
      t.integer :version_minor, null: false
      t.integer :version_patch, null: false
      t.json :content, null: false
      t.text :raw_content
      t.string :content_hash, null: false
      t.string :git_sha
      t.string :git_path
      t.text :changelog
      t.datetime :published_at
      t.string :published_by_id

      t.timestamps
    end

    add_index :api_spec_versions, :api_spec_id
    add_index :api_spec_versions, [:api_spec_id, :version], unique: true
    add_index :api_spec_versions, :git_sha
    add_index :api_spec_versions, :content_hash
    add_index :api_spec_versions, [:api_spec_id, :version_major, :version_minor, :version_patch],
              name: 'idx_api_spec_versions_semver'
    add_foreign_key :api_spec_versions, :api_specs
    add_foreign_key :api_spec_versions, :users, column: :published_by_id

    # Add foreign key for current_version_id
    add_foreign_key :api_specs, :api_spec_versions, column: :current_version_id

    # ============================================
    # Schema References (tracks relationships)
    # ============================================
    create_table :schema_references, id: :string do |t|
      t.string :source_type, null: false
      t.string :source_id, null: false
      t.string :source_version_id
      t.string :target_type, null: false
      t.string :target_id, null: false
      t.string :target_version_id
      t.string :reference_type, null: false
      t.string :reference_path

      t.timestamps
    end

    add_index :schema_references, [:source_type, :source_id]
    add_index :schema_references, [:target_type, :target_id]
    add_index :schema_references, :reference_type

    # ============================================
    # Tags
    # ============================================
    create_table :tags, id: :string do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :category
      t.string :color
      t.text :description

      t.timestamps
    end

    add_index :tags, :slug, unique: true
    add_index :tags, :category

    # ============================================
    # Taggings (polymorphic)
    # ============================================
    create_table :taggings, id: :string do |t|
      t.string :tag_id, null: false
      t.string :taggable_type, null: false
      t.string :taggable_id, null: false

      t.timestamps
    end

    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_type, :taggable_id]
    add_index :taggings, [:tag_id, :taggable_type, :taggable_id], unique: true
    add_foreign_key :taggings, :tags

    # ============================================
    # Access Grants
    # ============================================
    create_table :access_grants, id: :string do |t|
      t.string :grantable_type, null: false
      t.string :grantable_id, null: false
      t.string :grantee_type, null: false
      t.string :grantee_id, null: false
      t.string :permission, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :access_grants, [:grantable_type, :grantable_id]
    add_index :access_grants, [:grantee_type, :grantee_id]

    # ============================================
    # Audit Logs
    # ============================================
    create_table :audit_logs, id: :string do |t|
      t.string :auditable_type, null: false
      t.string :auditable_id, null: false
      t.string :user_id
      t.string :action, null: false
      t.json :changes_data
      t.json :metadata, default: {}
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :user_id
    add_index :audit_logs, :created_at
    add_foreign_key :audit_logs, :users

    # ============================================
    # Validation Cache
    # ============================================
    create_table :validation_caches, id: :string do |t|
      t.string :schema_type, null: false
      t.string :schema_id, null: false
      t.string :schema_version_id, null: false
      t.string :data_hash, null: false
      t.boolean :is_valid, null: false
      t.json :errors

      t.timestamps
    end

    add_index :validation_caches, [:schema_type, :schema_id, :data_hash]
    add_index :validation_caches, :created_at

    # ============================================
    # Webhook Subscriptions
    # ============================================
    create_table :webhook_subscriptions, id: :string do |t|
      t.string :user_id, null: false
      t.string :url, null: false
      t.string :secret
      t.text :events      # Store as JSON string
      t.text :schema_refs # Store as JSON string
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :webhook_subscriptions, :user_id
    add_index :webhook_subscriptions, :active
    add_foreign_key :webhook_subscriptions, :users
  end
end
