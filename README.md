# PDFMonkey

[![CI](https://github.com/pdfmonkey/pdfmonkey-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/pdfmonkey/pdfmonkey-ruby/actions/workflows/ci.yml)

This gem is the quickest way to use the [PDFMonkey](https://www.pdfmonkey.io) API.

## Installation

Add this line to your application’s Gemfile:

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

You can choose to set up your credentials explicitely in your application:

```ruby
Pdfmonkey.configure do |config|
  config.private_key = 'j39ckj4…'
end
```

### Generating a document

Once your App is created in the [PDFMonkey Dashboard](https://dashboard.pdfmonkey.io), create a Document Template and add the content you want to use. Every Document Template has a unique identifier (UUID), get your template’s identifier. Your ready to generate a Document.

#### Synchronous generation

If your want to wait for a Document’s generation before continuing with your workflow, use the `generate!` method, it will request a document generation and wait for it to succeed or fail before giving you any answer.

```ruby
template_id = 'b13ebd75-d290-409b-9cac-8f597ae3e785'
data = { name: 'John Doe' }

document = Pdfmonkey::Document.generate!(template_id, data)

document.status       # => 'success'
document.download_url # => 'https://…'
```

:warning: The download URL of a document is only valid **for 1 hour**. Passed this delay, reload the document to obtain a new one:

```ruby
document.reload!
```

#### Asynchronous generation

PDFMonkey was created with an asynchronous workflow in mind. It provides webhooks to inform you of a Document’s generation success or failure.

To leverage this behavior and continue working while your Document is generated, use the `generate` method:

```ruby
template_id = 'b13ebd75-d290-409b-9cac-8f597ae3e785'
data = { name: 'John Doe' }

document = Pdfmonkey::Document.generate(template_id, data)

document.status # => 'pending'
document.download_url # => nil
```

If you have a webhook URL set up it will be called with you document once the generation is complete. You can simulate it for testing with the following cURL command:

```ruby
curl <url of your app> \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{
        "document": {
          "app_id": "d9ec8249-65ae-4d50-8aee-7c12c1f9683a",
          "checksum": "ac0c2b6bcc77e2b01dc6ca6a9f656b2d",
          "created_at": "2020-01-02T03:04:05.000+01:00",
          "document_template_id": "f7fbe2b4-a57c-46ee-8422-5ae8cc37daac",
          "download_url": "https://example.com/76bebeb9-9eb1-481a-bc3c-faf43dc3ac81.pdf",
          "filename": "76bebeb9-9eb1-481a-bc3c-faf43dc3ac81.pdf",
          "id": "76bebeb9-9eb1-481a-bc3c-faf43dc3ac81",
          "meta": null,
          "payload": "{\"name\": \"John Doe\"}",
          "preview_url": null,
          "status": "success",
          "updated_at": "2020-01-02T03:04:15.000+01:00"
        }
      }'
```

#### Attaching meta data to the document

In addition to the Document’s payload you can add meta data when generating a Document.

This can be done by passing a third argument to the `generate!` and `generate` methods:

```ruby
meta = {
  _filename: 'john-doe-contract.pdf',
  client_id: '123xxx123'
}

document = Pdfmonkey::Document.generate!(template_id, payload, meta)
document.meta
# => '{"_filename":"john-doe-contract.pdf","client_id":"123xxx123"}'

document = Pdfmonkey::Document.generate(template_id, payload, meta)
document.meta
# => '{"_filename":"john-doe-contract.pdf","client_id":"123xxx123"}'
```

#### Error handling

In case of error, be it an HTTP layer error or an API error, `document.status` will be set to `'error'` and `document.error` will contain the error message.

```ruby
# Using an unknown template

template_id = 'unknown'
data = { name: 'John Doe' }

document = Pdfmonkey::Document.generate(template_id, data)

document.status # => 'error'
document.errors # => ["Document template must exist"]

# If your quota is depleted
document = Pdfmonkey::Document.generate(template_id, data)

document.status # => 'error'
document.errors # => { "status" => ["You’ve reached your quota for th..."] }

# If the network is down
document = Pdfmonkey::Document.generate(template_id, data)

document.status # => 'error'
document.errors # => ["Failed to open TCP connection to api.pdfmonkey.io:443 (getaddrinfo: nodename nor servname provided, or not known)"]
```

### Fetching a document

You can fetch an existing document using the `.fetch` method:

```ruby
document = Pdfmonkey::Document.fetch('76bebeb9-9eb1-481a-bc3c-faf43dc3ac81')
```

#### Error handling

In case of error, be it an HTTP layer error or an API error, `document.status` will be set to `'error'` and `document.error` will contain the error message.

```ruby
document = Pdfmonkey::Document.fetch('unknown')

document.status # => 'error'
document.errors # => ["We couldn't find any Document with ID \"unknown\"..."]

# If the network is down
document = Pdfmonkey::Document.fetch('95eb0b6e-090b-4195-9b7c-cc3d50099867')

document.status # => 'error'
document.errors # => ["Failed to open TCP connection to api.pdfmonkey.io:443 (getaddrinfo: nodename nor servname provided, or not known)"]
```

### Deleting a document

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

In case of error, be it an HTTP layer error or an API error, an error Hash will be returned.

```ruby
document.delete!
#=> true

document.delete!
# {
#   errors: ["We couldn't find any Document with ID \"11111111-2222-3333-4444-555555555555\". If ..."],
#   status: "error"
# }

# If the network is down
document.delete!
# {
#   errors: ["Failed to open TCP connection to api.pdfmonkey.io:443 (getaddrinfo: nodename nor servname provided, or not known)"],
#   status: "error"
# }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/simonc/pdfmonkey. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pdfmonkey project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/simonc/pdfmonkey/blob/master/CODE_OF_CONDUCT.md).
