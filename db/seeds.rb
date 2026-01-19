# frozen_string_literal: true

puts "Seeding TypeStore database..."

# Create admin user
admin = User.find_or_create_by!(email: 'admin@typestore.dev') do |user|
  user.name = 'Admin User'
  user.password = 'password123'
  user.role = 'admin'
end
puts "Created admin user: #{admin.email}"

# Generate API key for admin
api_key = admin.generate_api_key!
puts "Admin API key: #{api_key}"

# Create demo organization
org = Organization.find_or_create_by!(slug: 'demo-org') do |o|
  o.name = 'Demo Organization'
  o.description = 'Example organization for TypeStore demo'
end
org.add_member(admin, role: 'owner') unless org.member?(admin)
puts "Created organization: #{org.name}"

# Create namespaces
personal_ns = Namespace.find_or_create_by!(slug: '@demo') do |ns|
  ns.name = 'Demo Namespace'
  ns.description = 'Personal namespace for demo schemas'
  ns.visibility = 'public'
  ns.owner = admin
end
puts "Created namespace: #{personal_ns.display_slug}"

org_ns = Namespace.find_or_create_by!(slug: '@demo-org') do |ns|
  ns.name = 'Demo Organization'
  ns.description = 'Organization namespace for shared schemas'
  ns.visibility = 'public'
  ns.owner = org
end
puts "Created namespace: #{org_ns.display_slug}"

# Create tags
tags = %w[validation api common types utilities].map do |name|
  Tag.find_or_create_by!(name: name) do |t|
    t.slug = name.parameterize
    t.category = 'general'
  end
end
puts "Created #{tags.size} tags"

# Create example JSON Schema for Customer
customer_schema = {
  "$schema" => "https://json-schema.org/draft/2020-12/schema",
  "$id" => "https://typestore.dev/schemas/customer",
  "title" => "Customer",
  "description" => "A customer record",
  "type" => "object",
  "required" => ["id", "email", "name"],
  "properties" => {
    "id" => {
      "type" => "string",
      "format" => "uuid",
      "description" => "Unique customer identifier"
    },
    "email" => {
      "type" => "string",
      "format" => "email",
      "description" => "Customer email address"
    },
    "name" => {
      "type" => "string",
      "minLength" => 1,
      "maxLength" => 200,
      "description" => "Customer full name"
    },
    "phone" => {
      "type" => "string",
      "pattern" => "^\\+?[1-9]\\d{1,14}$",
      "description" => "Phone number in E.164 format"
    },
    "address" => {
      "$ref" => "#/$defs/Address"
    },
    "created_at" => {
      "type" => "string",
      "format" => "date-time"
    }
  },
  "$defs" => {
    "Address" => {
      "type" => "object",
      "properties" => {
        "street" => { "type" => "string" },
        "city" => { "type" => "string" },
        "state" => { "type" => "string" },
        "postal_code" => { "type" => "string" },
        "country" => { "type" => "string", "minLength" => 2, "maxLength" => 2 }
      },
      "required" => ["street", "city", "country"]
    }
  }
}

customer_shape = DataShape.find_or_create_by!(namespace: personal_ns, slug: 'customer') do |shape|
  shape.name = 'Customer'
  shape.format = 'json_schema'
  shape.description = 'JSON Schema for customer records'
end

unless customer_shape.versions.exists?(version: '1.0.0')
  customer_shape.versions.create!(
    version: '1.0.0',
    version_major: 1,
    version_minor: 0,
    version_patch: 0,
    content: customer_schema,
    content_hash: Digest::SHA256.hexdigest(customer_schema.to_json),
    changelog: 'Initial version of customer schema',
    published_by: admin,
    published_at: Time.current
  )
  customer_shape.update!(current_version: customer_shape.versions.first)
end
customer_shape.add_tag('validation')
customer_shape.add_tag('common')
puts "Created data shape: #{customer_shape.ref}"

# Create example JSON Schema for Order
order_schema = {
  "$schema" => "https://json-schema.org/draft/2020-12/schema",
  "$id" => "https://typestore.dev/schemas/order",
  "title" => "Order",
  "description" => "A customer order",
  "type" => "object",
  "required" => ["id", "customer_id", "items", "status"],
  "properties" => {
    "id" => {
      "type" => "string",
      "format" => "uuid"
    },
    "customer_id" => {
      "type" => "string",
      "format" => "uuid"
    },
    "items" => {
      "type" => "array",
      "minItems" => 1,
      "items" => {
        "$ref" => "#/$defs/OrderItem"
      }
    },
    "status" => {
      "type" => "string",
      "enum" => ["pending", "confirmed", "shipped", "delivered", "cancelled"]
    },
    "total_amount" => {
      "type" => "number",
      "minimum" => 0
    },
    "currency" => {
      "type" => "string",
      "minLength" => 3,
      "maxLength" => 3
    },
    "created_at" => {
      "type" => "string",
      "format" => "date-time"
    }
  },
  "$defs" => {
    "OrderItem" => {
      "type" => "object",
      "required" => ["product_id", "quantity", "unit_price"],
      "properties" => {
        "product_id" => { "type" => "string" },
        "quantity" => { "type" => "integer", "minimum" => 1 },
        "unit_price" => { "type" => "number", "minimum" => 0 }
      }
    }
  }
}

order_shape = DataShape.find_or_create_by!(namespace: personal_ns, slug: 'order') do |shape|
  shape.name = 'Order'
  shape.format = 'json_schema'
  shape.description = 'JSON Schema for order records'
end

unless order_shape.versions.exists?(version: '1.0.0')
  order_shape.versions.create!(
    version: '1.0.0',
    version_major: 1,
    version_minor: 0,
    version_patch: 0,
    content: order_schema,
    content_hash: Digest::SHA256.hexdigest(order_schema.to_json),
    changelog: 'Initial version of order schema',
    published_by: admin,
    published_at: Time.current
  )
  order_shape.update!(current_version: order_shape.versions.first)
end
order_shape.add_tag('validation')
puts "Created data shape: #{order_shape.ref}"

# Create example Type Definition for Email
email_type = TypeDefinition.find_or_create_by!(namespace: personal_ns, slug: 'email-address') do |td|
  td.name = 'Email Address'
  td.category = 'primitive'
  td.description = 'A valid email address format'
end

email_content = {
  "type" => "string",
  "format" => "email",
  "description" => "A valid email address",
  "examples" => ["user@example.com", "admin@company.org"]
}

unless email_type.versions.exists?(version: '1.0.0')
  email_type.versions.create!(
    version: '1.0.0',
    version_major: 1,
    version_minor: 0,
    version_patch: 0,
    content: email_content,
    content_hash: Digest::SHA256.hexdigest(email_content.to_json),
    changelog: 'Initial version',
    published_by: admin,
    published_at: Time.current
  )
  email_type.update!(current_version: email_type.versions.first)
end
email_type.add_tag('types')
puts "Created type definition: #{email_type.ref}"

# Create example OpenAPI spec
openapi_spec = {
  "openapi" => "3.1.0",
  "info" => {
    "title" => "Customer API",
    "version" => "1.0.0",
    "description" => "API for managing customers"
  },
  "servers" => [
    { "url" => "https://api.example.com/v1" }
  ],
  "paths" => {
    "/customers" => {
      "get" => {
        "summary" => "List all customers",
        "operationId" => "listCustomers",
        "responses" => {
          "200" => {
            "description" => "A list of customers",
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "array",
                  "items" => { "$ref" => "#/components/schemas/Customer" }
                }
              }
            }
          }
        }
      },
      "post" => {
        "summary" => "Create a customer",
        "operationId" => "createCustomer",
        "requestBody" => {
          "required" => true,
          "content" => {
            "application/json" => {
              "schema" => { "$ref" => "#/components/schemas/CustomerCreate" }
            }
          }
        },
        "responses" => {
          "201" => {
            "description" => "Customer created"
          }
        }
      }
    }
  },
  "components" => {
    "schemas" => {
      "Customer" => {
        "type" => "object",
        "properties" => {
          "id" => { "type" => "string", "format" => "uuid" },
          "email" => { "type" => "string", "format" => "email" },
          "name" => { "type" => "string" }
        }
      },
      "CustomerCreate" => {
        "type" => "object",
        "required" => ["email", "name"],
        "properties" => {
          "email" => { "type" => "string", "format" => "email" },
          "name" => { "type" => "string" }
        }
      }
    }
  }
}

customer_api = ApiSpec.find_or_create_by!(namespace: personal_ns, slug: 'customer-api') do |api|
  api.name = 'Customer API'
  api.spec_type = 'openapi'
  api.description = 'OpenAPI specification for customer management'
  api.base_url = 'https://api.example.com/v1'
end

unless customer_api.versions.exists?(version: '1.0.0')
  customer_api.versions.create!(
    version: '1.0.0',
    version_major: 1,
    version_minor: 0,
    version_patch: 0,
    content: openapi_spec,
    content_hash: Digest::SHA256.hexdigest(openapi_spec.to_json),
    changelog: 'Initial API version',
    published_by: admin,
    published_at: Time.current
  )
  customer_api.update!(current_version: customer_api.versions.first)
end
customer_api.add_tag('api')
puts "Created API spec: #{customer_api.ref}"

puts "\n=== TypeStore Seeding Complete ==="
puts "Admin email: admin@typestore.dev"
puts "Admin password: password123"
puts "Admin API key: #{api_key}"
puts "\nAvailable schemas:"
puts "  - #{customer_shape.ref}@1.0.0"
puts "  - #{order_shape.ref}@1.0.0"
puts "  - #{email_type.ref}@1.0.0"
puts "  - #{customer_api.ref}@1.0.0"
