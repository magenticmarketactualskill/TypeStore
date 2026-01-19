# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_18_000001) do
  create_table "access_grants", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "grantable_id", null: false
    t.string "grantable_type", null: false
    t.string "grantee_id", null: false
    t.string "grantee_type", null: false
    t.string "permission", null: false
    t.datetime "updated_at", null: false
    t.index ["grantable_type", "grantable_id"], name: "index_access_grants_on_grantable_type_and_grantable_id"
    t.index ["grantee_type", "grantee_id"], name: "index_access_grants_on_grantee_type_and_grantee_id"
  end

  create_table "api_spec_versions", id: :string, force: :cascade do |t|
    t.string "api_spec_id", null: false
    t.text "changelog"
    t.json "content", null: false
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.string "git_path"
    t.string "git_sha"
    t.datetime "published_at"
    t.string "published_by_id"
    t.text "raw_content"
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.integer "version_major", null: false
    t.integer "version_minor", null: false
    t.integer "version_patch", null: false
    t.index ["api_spec_id", "version"], name: "index_api_spec_versions_on_api_spec_id_and_version", unique: true
    t.index ["api_spec_id", "version_major", "version_minor", "version_patch"], name: "idx_api_spec_versions_semver"
    t.index ["api_spec_id"], name: "index_api_spec_versions_on_api_spec_id"
    t.index ["content_hash"], name: "index_api_spec_versions_on_content_hash"
    t.index ["git_sha"], name: "index_api_spec_versions_on_git_sha"
  end

  create_table "api_specs", id: :string, force: :cascade do |t|
    t.string "base_url"
    t.datetime "created_at", null: false
    t.string "current_version_id"
    t.boolean "deprecated", default: false
    t.text "deprecation_message"
    t.text "description"
    t.json "metadata", default: {}
    t.string "name", null: false
    t.string "namespace_id", null: false
    t.string "slug", null: false
    t.string "spec_type", null: false
    t.datetime "updated_at", null: false
    t.index ["deprecated"], name: "index_api_specs_on_deprecated"
    t.index ["namespace_id", "slug"], name: "index_api_specs_on_namespace_id_and_slug", unique: true
    t.index ["namespace_id"], name: "index_api_specs_on_namespace_id"
    t.index ["spec_type"], name: "index_api_specs_on_spec_type"
  end

  create_table "audit_logs", id: :string, force: :cascade do |t|
    t.string "action", null: false
    t.string "auditable_id", null: false
    t.string "auditable_type", null: false
    t.json "changes_data"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.json "metadata", default: {}
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.string "user_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "data_shapes", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "current_version_id"
    t.boolean "deprecated", default: false
    t.text "deprecation_message"
    t.text "description"
    t.string "format", null: false
    t.json "metadata", default: {}
    t.string "name", null: false
    t.string "namespace_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["deprecated"], name: "index_data_shapes_on_deprecated"
    t.index ["format"], name: "index_data_shapes_on_format"
    t.index ["namespace_id", "slug"], name: "index_data_shapes_on_namespace_id_and_slug", unique: true
    t.index ["namespace_id"], name: "index_data_shapes_on_namespace_id"
  end

  create_table "namespaces", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "owner_id", null: false
    t.string "owner_type", null: false
    t.json "settings", default: {}
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "private", null: false
    t.index ["owner_type", "owner_id"], name: "index_namespaces_on_owner_type_and_owner_id"
    t.index ["slug"], name: "index_namespaces_on_slug", unique: true
    t.index ["visibility"], name: "index_namespaces_on_visibility"
  end

  create_table "organization_memberships", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "organization_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["organization_id", "user_id"], name: "index_organization_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.json "settings", default: {}
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "schema_references", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "reference_path"
    t.string "reference_type", null: false
    t.string "source_id", null: false
    t.string "source_type", null: false
    t.string "source_version_id"
    t.string "target_id", null: false
    t.string "target_type", null: false
    t.string "target_version_id"
    t.datetime "updated_at", null: false
    t.index ["reference_type"], name: "index_schema_references_on_reference_type"
    t.index ["source_type", "source_id"], name: "index_schema_references_on_source_type_and_source_id"
    t.index ["target_type", "target_id"], name: "index_schema_references_on_target_type_and_target_id"
  end

  create_table "shape_versions", id: :string, force: :cascade do |t|
    t.text "changelog"
    t.json "content", null: false
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.string "data_shape_id", null: false
    t.string "git_path"
    t.string "git_sha"
    t.datetime "published_at"
    t.string "published_by_id"
    t.text "raw_content"
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.integer "version_major", null: false
    t.integer "version_minor", null: false
    t.integer "version_patch", null: false
    t.index ["content_hash"], name: "index_shape_versions_on_content_hash"
    t.index ["data_shape_id", "version"], name: "index_shape_versions_on_data_shape_id_and_version", unique: true
    t.index ["data_shape_id", "version_major", "version_minor", "version_patch"], name: "idx_shape_versions_semver"
    t.index ["data_shape_id"], name: "index_shape_versions_on_data_shape_id"
    t.index ["git_sha"], name: "index_shape_versions_on_git_sha"
  end

  create_table "taggings", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "tag_id", null: false
    t.string "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_on_tag_id_and_taggable_type_and_taggable_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
  end

  create_table "tags", id: :string, force: :cascade do |t|
    t.string "category"
    t.string "color"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_tags_on_category"
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "type_definitions", id: :string, force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "current_version_id"
    t.boolean "deprecated", default: false
    t.text "deprecation_message"
    t.text "description"
    t.json "metadata", default: {}
    t.string "name", null: false
    t.string "namespace_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_type_definitions_on_category"
    t.index ["deprecated"], name: "index_type_definitions_on_deprecated"
    t.index ["namespace_id", "slug"], name: "index_type_definitions_on_namespace_id_and_slug", unique: true
    t.index ["namespace_id"], name: "index_type_definitions_on_namespace_id"
  end

  create_table "type_versions", id: :string, force: :cascade do |t|
    t.text "changelog"
    t.json "content", null: false
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.string "git_path"
    t.string "git_sha"
    t.datetime "published_at"
    t.string "published_by_id"
    t.string "type_definition_id", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.integer "version_major", null: false
    t.integer "version_minor", null: false
    t.integer "version_patch", null: false
    t.index ["content_hash"], name: "index_type_versions_on_content_hash"
    t.index ["git_sha"], name: "index_type_versions_on_git_sha"
    t.index ["type_definition_id", "version"], name: "index_type_versions_on_type_definition_id_and_version", unique: true
    t.index ["type_definition_id", "version_major", "version_minor", "version_patch"], name: "idx_type_versions_semver"
    t.index ["type_definition_id"], name: "index_type_versions_on_type_definition_id"
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.string "api_key_digest"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.datetime "last_sign_in_at"
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
    t.json "settings", default: {}
    t.datetime "updated_at", null: false
    t.index ["api_key_digest"], name: "index_users_on_api_key_digest", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "validation_caches", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "data_hash", null: false
    t.json "errors"
    t.boolean "is_valid", null: false
    t.string "schema_id", null: false
    t.string "schema_type", null: false
    t.string "schema_version_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_validation_caches_on_created_at"
    t.index ["schema_type", "schema_id", "data_hash"], name: "idx_on_schema_type_schema_id_data_hash_2663da6831"
  end

  create_table "webhook_subscriptions", id: :string, force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "events"
    t.text "schema_refs"
    t.string "secret"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.string "user_id", null: false
    t.index ["active"], name: "index_webhook_subscriptions_on_active"
    t.index ["user_id"], name: "index_webhook_subscriptions_on_user_id"
  end

  add_foreign_key "api_spec_versions", "api_specs"
  add_foreign_key "api_spec_versions", "users", column: "published_by_id"
  add_foreign_key "api_specs", "api_spec_versions", column: "current_version_id"
  add_foreign_key "api_specs", "namespaces"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "data_shapes", "namespaces"
  add_foreign_key "data_shapes", "shape_versions", column: "current_version_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "shape_versions", "data_shapes"
  add_foreign_key "shape_versions", "users", column: "published_by_id"
  add_foreign_key "taggings", "tags"
  add_foreign_key "type_definitions", "namespaces"
  add_foreign_key "type_definitions", "type_versions", column: "current_version_id"
  add_foreign_key "type_versions", "type_definitions"
  add_foreign_key "type_versions", "users", column: "published_by_id"
  add_foreign_key "webhook_subscriptions", "users"
end
