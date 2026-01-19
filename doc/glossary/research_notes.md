# Research Notes: JSON Schema vs SHACL

## Source 1: "Validating ANYTHING With SHACL" by Kurt Cagle
URL: https://ontologist.substack.com/p/validating-anything-with-shacl

### Key Points:

**Historical Context:**
- SHACL introduced in 2017 as variation of SHEX (Shape Expression Language)
- Purpose: provide schema language aligned with XML Schema Definition Language (XSD) for RDF validation
- JSON Schema was proposed in 2013, ratified as ISO standard in 2017
- JSON Schema contains similar assertions and validations as XSD but in simpler format
- OpenAPI and Model Context Protocol borrow heavily from JSON Schema

**JSON Schema Background:**
- Originally JSON was notable for "not needing a schema" (Douglas Crockford)
- By 2013, need for consistency led to JSON Schema proposal
- Simpler format compared to XSD (which is considered a "monster of a specification")
- Used by OpenAPI (formerly Swagger) and Model Context Protocol for LLM-based agentic services

**SHACL Background:**
- Designed for RDF (Resource Description Framework) graph validation
- RDF emerged alongside XML but took different approach
- RDF design came from Cyc and formal logical systems
- SHACL works with RDF graphs and OWL (Web Ontology Language)
- Provides validation for knowledge graphs and semantic web applications

**Key Distinction:**
- JSON Schema: validates JSON documents (tree/hierarchical structures)
- SHACL: validates RDF graphs (graph-based linked data structures)


## Source 2: Reddit Discussion - r/semanticweb
URL: https://www.reddit.com/r/semanticweb/comments/1l4oved/

### Question:
User processing JSON-LD data in frontend application (interactive editor) asking whether JSON-LD framing + SHACL validation can enforce specific JSON structure, or if JSON Schema is better.

### Key Responses:

**Sten_Doipanni:**
- If you care about graph database, SHACL could be good option
- Otherwise, simple checks for "not null" values and existence of minimum set of keys could work
- Depends on underlying structure and desired outcome

**namedgraph:**
- "If you think about RDF in terms of a surface syntax such as JSON or XML, you will fail to write RDF-native code"
- Recommendation: Think about triples and validate them using SHACL
- Use RDF/JS to abstract syntax away (https://rdf.js.org)

**SpringOnionKiddo (Hybrid Approach):**
- Used JSON Schema for main syntax validation
- Then transformed to JSON-LD and validated nodes with SHACL for complex graph relationships
- This suggests a **two-stage validation approach**

### Insights:
- JSON Schema is ignorant of semantics, focuses on document structure
- SHACL validates graph relationships and semantic constraints
- Hybrid approach possible: JSON Schema first, then SHACL for graph validation
- Choice depends on whether you're working with graph databases and semantic relationships


## Source 3: IFC-LD Specification v0.2
URL: https://ifc-ld.org/releases/0.2/spec.html

### Key Statement on JSON Schema vs SHACL:

**Question: Why does IFC-LD recommend SHACL over JSON Schema?**

**Answer from specification:**
1. **Serialization-Agnosticism**: JSON Schema is applicable only to JSON, which itself is a data serialization format. IFC-LD must remain serialization-agnostic.
2. **Expressiveness**: "SHACL is also a more expressive schema language than JSON Schema. It is not possible to encode the existing IFC schemas in JSON Schema alone."

### SHACL Requirements for IFC-LD:

The schema language must be:
- At least as expressive as EXPRESS (complex schema language), including support for types, relations, and closed-world validation
- Serialization-agnostic (not tied to specific data format)
- Capable of supporting integration with domain-adjacent data models

### SHACL Capabilities Demonstrated:

SHACL can encode:
- Entity definitions (sh:NodeShape)
- Entity properties as first-class structured values
- Abstract entities (dash:abstract flag)
- Entity inheritance (sh:AndConstraintComponents)
- Types (sh:NodeShape targeting rdf:value)
- Enumerations (sh:PropertyShapes targeting sh:in)
- Selects (sh:NodeShape targeting sh:xone)
- Where Rules (SHACL Rules)
- Functions (SHACL Functions)

### Conclusion:
SHACL is more expressive than JSON Schema and can handle complex schema requirements that JSON Schema cannot encode alone.


## Source 4: JSON Schema Official Use Cases
URL: https://json-schema.org/overview/use-cases

### Primary Use Cases for JSON Schema:

1. **Structural Validation**: Validate JSON document structure (which properties must exist, expected types, value formats)

2. **Semantic Annotation**: Annotate values for machine readability and documentation purposes

3. **Domain-Specific Language**: Use internally within single application as declarative language for optimization

4. **Common Vocabulary**: Ensure identical validation behavior across multiple applications/platforms using same JSON documents

5. **Model-Driven UI Constraints**: Server declares constraints for form submissions, UI receives constraints for validation

6. **UI Generation**: Automatically generate user interfaces that adhere to schema

7. **Data Serialization**: Compress JSON data for storage/transmission

8. **Automated Testing**: Enable contract and property-based testing scenarios

9. **Machine-Readable Profiles**: Web servers link to profile documents describing data meaning

10. **Schema Inference**: Derive schema from large datasets to understand structure (data science)

11. **Hypermedia**: Support generic user-agents (browsers, spiders, automated tooling) with evolving schemas

12. **Results and Reporting**: Standard way to report validation results, annotations, and errors

13. **Intra-document Data Consistency**: Validate relational data within JSON document

14. **Inter-database Consistency**: Verify relational data against outside data sources

15. **Linting**: Enforce formatting requirements for aesthetic or compatibility reasons

### Key Strengths:
- REST API validation (request/response validation)
- OpenAPI and AsyncAPI integration
- Cross-platform consistency
- Automated testing and contract validation
- UI generation and form validation


## Source 5: W3C SHACL Use Cases and Requirements
URL: https://www.w3.org/TR/shacl-ucr/

### Primary Motivation: Application Integration

Different software components, potentially maintained by different organizations, need to function together smoothly. Example: international company with multiple divisions providing HR data feeds to various consuming applications.

### Key SHACL Benefits:

1. **Developers of data-consuming applications** can define shapes their software needs
2. **When modifying software**, developers can define new required shapes
3. **Management** can prioritize shapes based on applications that use them
4. **Data-providing systems** can read shape definitions to understand requirements
5. **Data providers** can validate their data against definitions
6. **Data consumers** can validate incoming data against expected shapes

### Selected Use Cases from W3C Document:

- **UC1: Model validation** - Validate RDF data against structural models
- **UC2: Enforcing cardinality** - Control min/max occurrences of properties
- **UC5: Complex constraints** - Express sophisticated validation rules
- **UC11: Model-Driven UI constraints** - Server declares constraints for form submissions
- **UC12: Application interoperability** - Ensure different applications work with same data
- **UC13: Metadata templates** - Validate metadata against templates
- **UC14: Quality Assurance** - Object reconciliation quality checks
- **UC16: Constraints and controlled reasoning** - Balance validation with inference
- **UC21: SKOS constraints** - Validate SKOS vocabularies
- **UC22: RDF Data Cube constraints** - Validate statistical data cubes
- **UC23: schema.org constraints** - Validate schema.org markup
- **UC27: Relationships between values** - Validate cross-property constraints
- **UC28: Self-Describing Linked Data** - Resources describe their own structure
- **UC34: Large-scale dataset validation** - Validate big knowledge graphs
- **UC42: Constraining RDF for JSON mapping** - Ensure RDF maps cleanly to JSON

### Key Strengths:
- Knowledge graph validation
- Cross-property and inter-node constraints
- Semantic web and linked data applications
- Complex relational constraints in graph structures
- Integration with RDF ecosystems (SPARQL, OWL, etc.)
