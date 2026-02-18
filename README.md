# PDFMonkey

[![CI](https://github.com/pdfmonkey/pdfmonkey-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/pdfmonkey/pdfmonkey-ruby/actions/workflows/ci.yml)

This gem is the quickest way to use the [PDFMonkey](https://www.pdfmonkey.io) API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pdfmonkey'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pdfmonkey

## Usage

### Setting up authentication

#### Using the default environment variables

PDFMonkey will look for the `PDFMONKEY_PRIVATE_KEY` environment variable. This variable should contain your private key obtained at https://dashboard.pdfmonkey.io/account.

    PDFMONKEY_PRIVATE_KEY=j39ckj4…

#### Setting credentials manually

You can choose to set up your credentials explicitly in your application:

```ruby
Pdfmonkey.configure do |config|
  config.private_key = 'j39ckj4…'
end
```

**Note:** Configuration is global. If you need per-request credentials (e.g. multi-tenant), use `with_adapter`:

```ruby
config = Pdfmonkey::Configuration.new
config.private_key = 'tenant-specific-key'

adapter = Pdfmonkey::Adapter.new(config: config)

Pdfmonkey.with_adapter(adapter) do
  Pdfmonkey::Document.generate!(
    document_template_id: 'b13ebd75-…',
    payload: { name: 'John Doe' }
  )
end
```

All operations inside the block use the given adapter. Calls outside the block continue using the global configuration.

### Documents

#### Synchronous generation

If you want to wait for a Document's generation before continuing with your workflow, use the `generate!` method, it will request a document generation and wait for it to succeed or fail before giving you any answer.

```ruby
document = Pdfmonkey::Document.generate!(
  document_template_id: 'b13ebd75-d290-409b-9cac-8f597ae3e785',
  payload: { name: 'John Doe' }
)

document.status       # => 'success'
document.download_url # => 'https://…'
```

**Warning:** The download URL of a document is only valid **for 1 hour**. Past this delay, reload the document to obtain a new one:

```ruby
document.reload!
```

#### Asynchronous generation

PDFMonkey was created with an asynchronous workflow in mind. It provides webhooks to inform you of a Document's generation success or failure.

To leverage this behavior and continue working while your Document is being generated, use the `generate` method:

```ruby
document = Pdfmonkey::Document.generate(
  document_template_id: 'b13ebd75-d290-409b-9cac-8f597ae3e785',
  payload: { name: 'John Doe' }
)

document.status # => 'pending'
document.download_url # => nil
```

If you have a webhook URL set up it will be called with your document once the generation is complete. You can simulate it for testing with the following cURL command:

```bash
curl <url of your app> \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{
        "document": {
          "id": "76bebeb9-9eb1-481a-bc3c-faf43dc3ac81",
          "app_id": "d9ec8249-65ae-4d50-8aee-7c12c1f9683a",
          "created_at": "2020-01-02T03:04:05.000+01:00",
          "document_template_id": "f7fbe2b4-a57c-46ee-8422-5ae8cc37daac",
          "meta": "{\"_filename\":\"my-doc.pdf\"}",
          "output_type": "pdf",
          "status": "success",
          "updated_at": "2020-01-02T03:04:15.000+01:00",
          "xml_data": null,
          "payload": "{\"name\": \"John Doe\"}",
          "download_url": "https://example.com/76bebeb9-9eb1-481a-bc3c-faf43dc3ac81.pdf",
          "checksum": "ac0c2b6bcc77e2b01dc6ca6a9f656b2d",
          "failure_cause": null,
          "filename": "my-doc.pdf",
          "generation_logs": [],
          "preview_url": "https://preview.pdfmonkey.io/pdf/web/viewer.html?file=https%3A%2F%2Fpreview.pdfmonkey.io%2Fdocument-render%2F76bebeb9-9eb1-481a-bc3c-faf43dc3ac81%2Fac0c2b6bcc77e2b01dc6ca6a9f656b2d",
          "public_share_link": "https://example.com/76bebeb9-9eb1-481a-bc3c-faf43dc3ac81.pdf"
        }
      }'
```

#### Draft documents

You can create a draft document that won't be queued for generation.

> [!TIP]
> This is useful for embedding a preview via `preview_url` before triggering generation. That what we do in the PDFMonkey dashboard to show you a preview of your document before generating it, using an `iframe`.

```ruby
draft = Pdfmonkey::Document.create_draft(
  document_template_id: 'b13ebd75-d290-409b-9cac-8f597ae3e785',
  payload: { name: 'John Doe' }
)
draft.status      # => 'draft'
draft.preview_url # => 'https://…'

# When ready, trigger generation and wait for completion:
draft.generate!
draft.status # => 'success'
draft.download_url # => 'https://…'

# Or trigger generation without waiting:
draft.generate
draft.status # => 'pending'
```

#### Attaching meta data to the document

In addition to the Document's payload you can add meta data when generating a Document.

This can be done by passing the `meta:` keyword argument to the `generate!` and `generate` methods:

```ruby
meta = {
  _filename: 'john-doe-contract.pdf',
  client_id: '123xxx123'
}

document = Pdfmonkey::Document.generate!(
  document_template_id: template_id,
  payload: payload,
  meta: meta
)
document.meta
# => '{"_filename":"john-doe-contract.pdf","client_id":"123xxx123"}'

document = Pdfmonkey::Document.generate(
  document_template_id: template_id,
  payload: payload,
  meta: meta
)
document.meta
# => '{"_filename":"john-doe-contract.pdf","client_id":"123xxx123"}'
```

#### Image generation

Image generation uses the same API flow as PDF generation. The template's `output_type` attribute indicates whether it produces `'pdf'` or `'image'` output. Image-specific options are passed through the `meta` parameter:

```ruby
doc = Pdfmonkey::Document.generate!(
  document_template_id: template_id,
  payload: payload,
  meta: {
    _type: 'png',       # webp (default), png, or jpg
    _width: 800,        # pixels
    _height: 600,       # pixels
    _quality: 80        # webp only, default 100
  }
)
doc.download_url # => URL to the generated image
```

#### Updating a document

```ruby
document.update!(status: 'pending')
```

#### Listing documents

```ruby
cards = Pdfmonkey::Document.list_cards(page: 1, status: 'success')

cards.each do |card|
  puts card.id
  puts card.status
end

cards.current_page  # => 1
cards.total_pages   # => 5

# Navigate pages
next_cards = cards.next_page
prev_cards = cards.prev_page
```

You can filter by `document_template_id:`, `status:`, `workspace_id:`, and `updated_since:`.

#### Fetching a document

> [!CAUTION]
> Fetching a full document includes its payload, meaning it could be large depending on the data you provided. We **strongly** recommend using only `fetch_card` unless you have a specific reason to fetch the full document.

You can fetch an existing document using `.fetch` (or its explicit alias `.fetch_full`):

```ruby
document = Pdfmonkey::Document.fetch('76bebeb9-9eb1-481a-bc3c-faf43dc3ac81')
```

To fetch just the lightweight card representation (recommended):

```ruby
card = Pdfmonkey::Document.fetch_card('76bebeb9-9eb1-481a-bc3c-faf43dc3ac81')
```

#### Deleting a document

You can delete an existing document using the `.delete` method:

```ruby
Pdfmonkey::Document.delete('76bebeb9-9eb1-481a-bc3c-faf43dc3ac81')
#=> true
```

Alternatively you can call the `#delete!` method:

```ruby
document.delete!
#=> true
```

#### Error handling

API errors and network errors raise exceptions:

```ruby
begin
  document = Pdfmonkey::Document.generate(
    document_template_id: template_id,
    payload: data
  )
rescue Pdfmonkey::ApiError => e
  e.message     # => "Document template must exist"
  e.errors      # => ["Document template must exist"]
  e.status_code # => 422
rescue Pdfmonkey::ConnectionError => e
  e.message # => "Failed to open TCP connection to api.pdfmonkey.io:443 ..."
end
```

When using `generate!`, an additional exception may be raised if the document's status is `'error'` or `'failure'`:

```ruby
begin
  document = Pdfmonkey::Document.generate!(
    document_template_id: template_id,
    payload: data
  )
rescue Pdfmonkey::GenerationError => e
  e.message  # => "Document generation failed: Template error"
  e.document # => #<Pdfmonkey::Document …> (the failed document)
end
```

All exception classes inherit from `Pdfmonkey::Error`, so you can rescue broadly:

```ruby
begin
  document = Pdfmonkey::Document.generate!(
    document_template_id: template_id,
    payload: data
  )
rescue Pdfmonkey::Error => e
  puts "Something went wrong: #{e.message}"
end
```

### Templates

#### Fetching a template

> [!CAUTION]
> Fetching a full template includes its body and settings, which can be large. Use `list_cards` when you only need metadata.

```ruby
template = Pdfmonkey::Template.fetch('b13ebd75-d290-409b-9cac-8f597ae3e785')
template.identifier # => 'my-invoice'
template.body       # => '<h1>Invoice</h1>…'  (published version)
template.body_draft # => '<h1>Invoice v2</h1>…'  (draft version)
```

You can also use the explicit alias `.fetch_full`:

```ruby
template = Pdfmonkey::Template.fetch_full('b13ebd75-d290-409b-9cac-8f597ae3e785')
```

#### Creating a template

When creating a template, attributes like `body`, `scss_style`, `settings`, `sample_data`, and `pdf_engine_id` are automatically written to their draft counterparts (`body_draft`, `scss_style_draft`, etc.):

```ruby
template = Pdfmonkey::Template.create(
  identifier: 'my-invoice',
  body: '<h1>Invoice</h1>'
)
template.body_draft # => '<h1>Invoice</h1>'
```

#### Updating a template

Like `create`, `update!` writes to the draft fields:

```ruby
template.update!(body: '<h1>Updated Invoice</h1>')
template.body_draft # => '<h1>Updated Invoice</h1>'
```

#### Publishing a template

Once you're happy with the draft, publish it to copy all draft fields to their published counterparts:

```ruby
template.publish!
template.body # => '<h1>Updated Invoice</h1>'
```

#### Listing templates

```ruby
cards = Pdfmonkey::Template.list_cards(workspace_id: 'f4ab650c-…')
```

#### Deleting a template

```ruby
Pdfmonkey::Template.delete('b13ebd75-…')
# or
template.delete!
```

### Template Folders

```ruby
# List folders
folders = Pdfmonkey::TemplateFolder.list

# Create a folder
folder = Pdfmonkey::TemplateFolder.create(identifier: 'invoices')

# Fetch a folder
folder = Pdfmonkey::TemplateFolder.fetch('folder-id')

# Update a folder
folder.update!(identifier: 'receipts')

# Delete a folder
Pdfmonkey::TemplateFolder.delete('folder-id')
# or
folder.delete!
```

To create a template inside a specific folder, pass the `template_folder_id`:

```ruby
folder = Pdfmonkey::TemplateFolder.create(identifier: 'invoices')

template = Pdfmonkey::Template.create(
  identifier: 'monthly-invoice',
  body: '<h1>Invoice</h1>',
  template_folder_id: folder.id
)
```

### Snippets

Snippets are reusable HTML components that can be included in templates.

```ruby
# List snippets
snippets = Pdfmonkey::Snippet.list

# Create a snippet
snippet = Pdfmonkey::Snippet.create(
  identifier: 'header',
  code: '<div class="header">…</div>',
  workspace_id: 'f4ab650c-…'
)

# Fetch a snippet
snippet = Pdfmonkey::Snippet.fetch('snippet-id')

# Update a snippet
snippet.update!(code: '<div class="header">Updated</div>')

# Delete a snippet
Pdfmonkey::Snippet.delete('snippet-id')
# or
snippet.delete!
```

### Workspaces

Workspaces are read-only resources. They can be listed and fetched but not created, updated, or deleted through the API.

```ruby
# List workspaces
workspaces = Pdfmonkey::Workspace.list_cards

workspaces.each do |workspace|
  puts workspace.identifier
end

# Fetch a workspace
workspace = Pdfmonkey::Workspace.fetch('workspace-id')
workspace.identifier # => 'my-app'
```

### Webhooks

Webhooks allow you to receive notifications when documents are generated.

```ruby
# Create a webhook for all templates in a workspace
webhook = Pdfmonkey::Webhook.create(
  url: 'https://example.com/webhooks/pdfmonkey',
  event: 'document.generation.completed',
  workspace_id: 'f4ab650c-…'
)

# Optionally restrict to specific templates
webhook = Pdfmonkey::Webhook.create(
  url: 'https://example.com/webhooks/pdfmonkey',
  event: 'document.generation.completed',
  workspace_id: 'f4ab650c-…',
  document_template_ids: ['tpl-1', 'tpl-2']
)

# You can also specify a custom channel for routing
webhook = Pdfmonkey::Webhook.create(
  url: 'https://example.com/webhooks/pdfmonkey',
  event: 'document.generation.completed',
  workspace_id: 'f4ab650c-…',
  custom_channel: 'invoices'
)

# Delete a webhook
Pdfmonkey::Webhook.delete('webhook-id')
# or
webhook.delete!
```

### Engines

List available PDF rendering engines:

```ruby
engines = Pdfmonkey::Engine.list

engines.each do |engine|
  puts "#{engine.name} (deprecated: #{engine.deprecated_on || 'no'})"
end
```

You can use an engine when creating a template:

```ruby
engines = Pdfmonkey::Engine.list
v4 = engines.find { |e| e.name == 'v4' }

template = Pdfmonkey::Template.create(
  identifier: 'my-template',
  body: '<h1>Hello</h1>',
  pdf_engine_id: v4.id
)
```

### Current User

Retrieve information about the authenticated user:

```ruby
user = Pdfmonkey::CurrentUser.fetch

user.email              # => 'user@example.com'
user.current_plan       # => 'pro'
user.available_documents # => 1000
```

### Pagination

All list methods return `Pdfmonkey::Collection` objects that support pagination:

```ruby
collection = Pdfmonkey::Document.list_cards(page: 1)

collection.current_page    # => 1
collection.total_pages     # => 5
collection.next_page_number # => 2
collection.prev_page_number # => nil

# Navigate to next/previous pages
next_page = collection.next_page  # => Collection or nil
prev_page = collection.prev_page  # => Collection or nil
```

Collections are `Enumerable`. Methods like `.each`, `.map`, and `.select` operate on the items **of the current page only** — they do not automatically fetch subsequent pages:

```ruby
# These all act on the current page's items
collection.each { |item| puts item.id }
collection.map(&:status)
collection.select { |item| item.status == 'success' }

# To process all pages, navigate manually
page = Pdfmonkey::Template.list_cards(page: 1)
while page
  page.each { |item| process(item) }
  page = page.next_page
end
```

### Serialization

All resources support `to_json` and `to_h`:

```ruby
document.to_json # => '{"document":{"id":"…","status":"success",…}}'
document.to_h    # => {id: "…", status: "success", errors: nil, …}
```

`to_json` wraps attributes under the resource's API member key, omits `nil` values and strips the `errors` attribute (it is intended for API requests). Use `to_h` when you need the full attribute hash for logging or caching.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pdfmonkeyio/pdfmonkey-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pdfmonkey project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pdfmonkeyio/pdfmonkey-ruby/blob/master/CODE_OF_CONDUCT.md).
