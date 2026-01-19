# frozen_string_literal: true

module SemanticVersioning
  extend ActiveSupport::Concern

  SEMVER_REGEX = /\A(\d+)\.(\d+)\.(\d+)(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?\z/

  included do
    validates :version, format: { with: SEMVER_REGEX, message: 'must be valid semver (e.g., 1.0.0)' }
  end

  def parse_version
    return unless version.present?

    match = version.match(SEMVER_REGEX)
    return unless match

    self.version_major = match[1].to_i
    self.version_minor = match[2].to_i
    self.version_patch = match[3].to_i
  end

  def prerelease?
    version.include?('-')
  end

  def prerelease_tag
    return nil unless prerelease?

    version.split('-', 2).last.split('+').first
  end

  def build_metadata
    return nil unless version.include?('+')

    version.split('+', 2).last
  end

  # Compare versions
  def <=>(other)
    return nil unless other.is_a?(self.class)

    [version_major, version_minor, version_patch] <=> [other.version_major, other.version_minor, other.version_patch]
  end

  def newer_than?(other)
    (self <=> other) == 1
  end

  def older_than?(other)
    (self <=> other) == -1
  end

  def same_version?(other)
    (self <=> other) == 0
  end

  # Check if this version is compatible with a constraint
  def satisfies?(constraint)
    return true if constraint.blank?

    # Exact match
    if constraint.match?(SEMVER_REGEX)
      return version == constraint
    end

    # Caret: ^1.0.0 -> >=1.0.0 <2.0.0
    if constraint.start_with?('^')
      target = parse_constraint_version(constraint[1..])
      return version_major == target[:major] &&
             (version_minor > target[:minor] ||
              (version_minor == target[:minor] && version_patch >= target[:patch]))
    end

    # Tilde: ~1.0.0 -> >=1.0.0 <1.1.0
    if constraint.start_with?('~')
      target = parse_constraint_version(constraint[1..])
      return version_major == target[:major] &&
             version_minor == target[:minor] &&
             version_patch >= target[:patch]
    end

    # Greater than or equal: >=1.0.0
    if constraint.start_with?('>=')
      target = parse_constraint_version(constraint[2..])
      return compare_to_target(target) >= 0
    end

    # Less than: <2.0.0
    if constraint.start_with?('<') && !constraint.start_with?('<=')
      target = parse_constraint_version(constraint[1..])
      return compare_to_target(target) < 0
    end

    false
  end

  private

  def parse_constraint_version(str)
    parts = str.strip.split('.')
    {
      major: parts[0].to_i,
      minor: (parts[1] || '0').to_i,
      patch: (parts[2] || '0').to_i
    }
  end

  def compare_to_target(target)
    [version_major, version_minor, version_patch] <=> [target[:major], target[:minor], target[:patch]]
  end
end
