# SHACL - Shapes Constraint Language

**SHACL** (Shapes Constraint Language) is a W3C standard language for validating RDF (Resource Description Framework) graphs against a set of conditions. It allows data architects and developers to define "shapes" that describe the expected structure, constraints, and relationships in graph-based data models. SHACL is used to ensure data quality and consistency in knowledge graphs, semantic web applications, and linked data systems by specifying rules that data must conform to.

## Validation and Constraints

SHACL provides a rich vocabulary for expressing constraints on RDF data, including cardinality restrictions, value type requirements, pattern matching, and logical combinations of constraints. A SHACL document defines shapes that target specific classes or nodes in an RDF graph, specifying what properties they should have and what values are acceptable. When validation is performed, SHACL processors generate validation reports indicating which constraints were violated, making it easier to identify and fix data quality issues in large knowledge graphs.

## External References

- [W3C: Shapes Constraint Language (SHACL)](https://www.w3.org/TR/shacl/) - Official W3C Recommendation (July 2017)
- [W3C: SHACL 1.2 Rules](https://www.w3.org/TR/shacl12-rules/) - Extended specification for SHACL rules (December 2025)
- [Ontotext: What Is SHACL?](https://www.ontotext.com/knowledgehub/fundamentals/what-is-shacl/) - Practical introduction to SHACL concepts
- [SHACL Compact Syntax](https://w3c.github.io/data-shapes/shacl12-cs/) - Alternative compact syntax for writing SHACL shapes
