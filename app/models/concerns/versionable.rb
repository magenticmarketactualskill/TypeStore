# frozen_string_literal: true

module Versionable
  extend ActiveSupport::Concern

  included do
    # Subclasses must define:
    # - belongs_to :current_version
    # - has_many :versions
  end

  def version_count
    versions.count
  end

  def has_versions?
    versions.exists?
  end

  def published_versions
    versions.published.ordered
  end

  def draft_versions
    versions.draft.ordered
  end

  # Find version matching semver constraint
  # Supports: exact (1.0.0), caret (^1.0), tilde (~1.0), range (>=1.0.0 <2.0.0)
  def resolve_version(constraint)
    return latest_version if constraint.blank? || constraint == 'latest'

    # Exact version
    if constraint.match?(/^\d+\.\d+\.\d+$/)
      return versions.find_by(version: constraint)
    end

    # Caret constraint: ^1.0.0 means >=1.0.0 <2.0.0
    if constraint.start_with?('^')
      major = constraint[1..].split('.').first.to_i
      return versions.where(version_major: major).ordered.first
    end

    # Tilde constraint: ~1.0.0 means >=1.0.0 <1.1.0
    if constraint.start_with?('~')
      parts = constraint[1..].split('.')
      major = parts[0].to_i
      minor = parts[1].to_i
      return versions.where(version_major: major, version_minor: minor).ordered.first
    end

    # Fallback to latest
    latest_version
  end

  # Create a new version
  def create_version(content:, version: nil, changelog: nil, published_by: nil)
    version ||= next_version
    version_class = self.class.reflect_on_association(:versions).klass

    new_version = versions.build(
      version: version,
      content: content,
      changelog: changelog,
      published_by: published_by
    )

    if new_version.save
      update!(current_version: new_version) if published_by
    end

    new_version
  end

  def next_version(bump_type = :patch)
    current = latest_version

    if current.nil?
      return '1.0.0'
    end

    major = current.version_major
    minor = current.version_minor
    patch = current.version_patch

    case bump_type
    when :major
      "#{major + 1}.0.0"
    when :minor
      "#{major}.#{minor + 1}.0"
    when :patch
      "#{major}.#{minor}.#{patch + 1}"
    end
  end
end
