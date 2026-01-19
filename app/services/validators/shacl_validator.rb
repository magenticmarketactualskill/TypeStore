# frozen_string_literal: true

require 'rdf'
require 'rdf/turtle'
require 'json/ld'
require 'shacl'

module Validators
  class ShaclValidator
    def initialize(shapes_content)
      @shapes_graph = RDF::Graph.new

      # Parse shapes - could be JSON-LD or Turtle
      if shapes_content.is_a?(Hash) || shapes_content.is_a?(String) && shapes_content.strip.start_with?('{')
        # JSON-LD
        JSON::LD::API.toRdf(shapes_content.is_a?(String) ? JSON.parse(shapes_content) : shapes_content) do |statement|
          @shapes_graph << statement
        end
      else
        # Turtle
        @shapes_graph << RDF::Turtle::Reader.new(shapes_content.to_s)
      end
    end

    def validate(data, options = {})
      # Convert data to RDF graph
      data_graph = to_rdf_graph(data)

      # Run SHACL validation
      report = SHACL.execute(@shapes_graph, data_graph)

      {
        valid: report.conform?,
        errors: format_results(report.results.reject(&:conform?)),
        warnings: extract_warnings(report)
      }
    rescue StandardError => e
      {
        valid: false,
        errors: [{ message: "SHACL validation error: #{e.message}", type: 'validation_error' }],
        warnings: []
      }
    end

    private

    def to_rdf_graph(data)
      graph = RDF::Graph.new

      if data.is_a?(Hash)
        # Assume JSON-LD
        JSON::LD::API.toRdf(data) do |statement|
          graph << statement
        end
      elsif data.is_a?(String)
        if data.strip.start_with?('{', '[')
          # JSON-LD string
          JSON::LD::API.toRdf(JSON.parse(data)) do |statement|
            graph << statement
          end
        else
          # Turtle or other RDF format
          graph << RDF::Turtle::Reader.new(data)
        end
      end

      graph
    end

    def format_results(results)
      results.map do |result|
        {
          path: result.path&.to_s,
          focus_node: result.focus_node&.to_s,
          message: extract_message(result),
          severity: extract_severity(result),
          constraint: result.source_constraint_component&.to_s&.split('#')&.last,
          value: result.value&.to_s
        }
      end
    end

    def extract_message(result)
      messages = result.message
      return messages.first.to_s if messages.respond_to?(:first) && messages.first

      "Validation constraint violated: #{result.source_constraint_component}"
    end

    def extract_severity(result)
      severity = result.severity&.to_s
      return 'violation' unless severity

      case severity
      when /Violation/i then 'violation'
      when /Warning/i then 'warning'
      when /Info/i then 'info'
      else 'violation'
      end
    end

    def extract_warnings(report)
      report.results
            .select { |r| r.severity&.to_s&.match?(/Warning/i) }
            .map do |result|
        {
          path: result.path&.to_s,
          focus_node: result.focus_node&.to_s,
          message: extract_message(result),
          type: 'warning'
        }
      end
    end
  end
end
