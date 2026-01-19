# frozen_string_literal: true

class CreateCoreTables < ActiveRecord::Migration[8.1]
  def change
    # Enable UUID extension
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    # ============================================
    # Users
    # ============================================
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :encrypted_password, null: false
      t.string :api_key_digest
      t.string :role, default: 'user', null: false
      t.jsonb :settings, default: {}
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
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :organizations, :slug, unique: true

    # ============================================
    # Organization Memberships
    # ============================================
    create_table :organization_memberships, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :role, default: 'member', null: false

      t.timestamps
    end

    add_index :organization_memberships, [:organization_id, :user_id], unique: true

    # ============================================
    # Namespaces
    # ============================================
    create_table :namespaces, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :visibility, default: 'private', null: false
      t.string :owner_type, null: false
      t.uuid :owner_id, null: false
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :namespaces, :slug, unique: true
    add_index :namespaces, [:owner_type, :owner_id]
    add_index :namespaces, :visibility

    # ============================================
    # Type Definitions
    # ============================================
    create_table :type_definitions, id: :uuid do |t|
      t.references :namespace, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :category, null: false
      t.uuid :current_version_id
      t.boolean :deprecated, default: false
      t.text :deprecation_message
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :type_definitions, [:namespace_id, :slug], unique: true
    add_index :type_definitions, :category
    add_index :type_definitions, :deprecated

    # ============================================
    # Type Versions
    # ============================================
    create_table :type_versions, id: :uuid do |t|
      t.references :type_definition, null: false, foreign_key: true, type: :uuid
      t.string :version, null: false
      t.integer :version_major, null: false
      t.integer :version_minor, null: false
      t.integer :version_patch, null: false
      t.jsonb :content, null: false
      t.string :content_hash, null: false
      t.string :git_sha
      t.string :git_path
      t.text :changelog
      t.datetime :published_at
      t.references :published_by, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    add_index :type_versions, [:type_definition_id, :version], unique: true
    add_index :type_versions, :git_sha
    add_index :type_versions, :content_hash
    add_index :type_versions, [:type_definition_id, :version_major, :version_minor, :version_patch],
              name: 'idx_type_versions_semver'

    # Add foreign key for current_version_id
    add_foreign_key :type_definitions, :type_versions, column: :current_version_id

    # ============================================
    # Data Shapes
    # ============================================
    create_table :data_shapes, id: :uuid do |t|
      t.references :namespace, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :slug, null: false
      t.string :format, null: false
      t.text :description
      t.uuid :current_version_id
      t.boolean :deprecated, default: false
      t.text :deprecation_message
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :data_shapes, [:namespace_id, :slug], unique: true
    add_index :data_shapes, :format
    add_index :data_shapes, :deprecated

    # ============================================
    # Shape Versions
    # ============================================
    create_table :shape_versions, id: :uuid do |t|
      t.references :data_shape, null: false, foreign_key: true, type: :uuid
      t.string :version, null: false
      t.integer :version_major, null: false
      t.integer :version_minor, null: false
      t.integer :version_patch, null: false
      t.jsonb :content, null: false
      t.text :raw_content
      t.string :content_hash, null: false
      t.string :git_sha
      t.string :git_path
      t.text :changelog
      t.datetime :published_at
      t.references :published_by, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    add_index :shape_versions, [:data_shape_id, :version], unique: true
    add_index :shape_versions, :git_sha
    add_index :shape_versions, :content_hash
    add_index :shape_versions, [:data_shape_id, :version_major, :version_minor, :version_patch],
              name: 'idx_shape_versions_semver'

    # Add foreign key for current_version_id
    add_foreign_key :data_shapes, :shape_versions, column: :current_version_id

    # ============================================
    # API Specs
    # ============================================
    create_table :api_specs, id: :uuid do |t|
      t.references :namespace, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :slug, null: false
      t.string :spec_type, null: false
      t.text :description
      t.uuid :current_version_id
      t.boolean :deprecated, default: false
      t.text :deprecation_message
      t.string :base_url
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :api_specs, [:namespace_id, :slug], unique: true
    add_index :api_specs, :spec_type
    add_index :api_specs, :deprecated

    # ============================================
    # API Spec Versions
    # ============================================
    create_table :api_spec_versions, id: :uuid do |t|
      t.references :api_spec, null: false, foreign_key: true, type: :uuid
      t.string :version, null: false
      t.integer :version_major, null: false
      t.integer :version_minor, null: false
      t.integer :version_patch, null: false
      t.jsonb :content, null: false
      t.text :raw_content
      t.string :content_hash, null: false
      t.string :git_sha
      t.string :git_path
      t.text :changelog
      t.datetime :published_at
      t.references :published_by, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    add_index :api_spec_versions, [:api_spec_id, :version], unique: true
    add_index :api_spec_versions, :git_sha
    add_index :api_spec_versions, :content_hash
    add_index :api_spec_versions, [:api_spec_id, :version_major, :version_minor, :version_patch],
              name: 'idx_api_spec_versions_semver'

    # Add foreign key for current_version_id
    add_foreign_key :api_specs, :api_spec_versions, column: :current_version_id

    # ============================================
    # Schema References (tracks relationships)
    # ============================================
    create_table :schema_references, id: :uuid do |t|
      t.string :source_type, null: false
      t.uuid :source_id, null: false
      t.uuid :source_version_id
      t.string :target_type, null: false
      t.uuid :target_id, null: false
      t.uuid :target_version_id
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
    create_table :tags, id: :uuid do |t|
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
    create_table :taggings, id: :uuid do |t|
      t.references :tag, null: false, foreign_key: true, type: :uuid
      t.string :taggable_type, null: false
      t.uuid :taggable_id, null: false

      t.timestamps
    end

    add_index :taggings, [:taggable_type, :taggable_id]
    add_index :taggings, [:tag_id, :taggable_type, :taggable_id], unique: true

    # ============================================
    # Access Grants
    # ============================================
    create_table :access_grants, id: :uuid do |t|
      t.string :grantable_type, null: false
      t.uuid :grantable_id, null: false
      t.string :grantee_type, null: false
      t.uuid :grantee_id, null: false
      t.string :permission, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :access_grants, [:grantable_type, :grantable_id]
    add_index :access_grants, [:grantee_type, :grantee_id]

    # ============================================
    # Audit Logs
    # ============================================
    create_table :audit_logs, id: :uuid do |t|
      t.string :auditable_type, null: false
      t.uuid :auditable_id, null: false
      t.references :user, foreign_key: true, type: :uuid
      t.string :action, null: false
      t.jsonb :changes_data
      t.jsonb :metadata, default: {}
      t.inet :ip_address
      t.text :user_agent

      t.timestamps
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :created_at

    # ============================================
    # Validation Cache
    # ============================================
    create_table :validation_caches, id: :uuid do |t|
      t.string :schema_type, null: false
      t.uuid :schema_id, null: false
      t.uuid :schema_version_id, null: false
      t.string :data_hash, null: false
      t.boolean :is_valid, null: false
      t.jsonb :errors

      t.timestamps
    end

    add_index :validation_caches, [:schema_type, :schema_id, :data_hash]
    add_index :validation_caches, :created_at

    # ============================================
    # Webhook Subscriptions
    # ============================================
    create_table :webhook_subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :url, null: false
      t.string :secret
      t.string :events, array: true, default: []
      t.string :schema_refs, array: true, default: []
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :webhook_subscriptions, :active
  end
end
