# Changelog

## Unreleased

### Breaking changes

* **Requiring Ruby >= 3.2** — The gem now requires Ruby 3.2 or later.
* **Exception-based error handling** — API errors now raise `Pdfmonkey::ApiError` (with `errors` and `status_code` attributes) and network errors raise `Pdfmonkey::ConnectionError` instead of returning error hashes. Rescue `Pdfmonkey::Error` for a catch-all.
* **`Document.generate!` / `Document.generate` signature change** — These methods now use keyword arguments (`document_template_id:`, `payload:`, `meta:`). Positional arguments still work but emit a deprecation warning.
* **`Document.generate!` raises on failure** — `Document.generate!` now raises `Pdfmonkey::GenerationError` when the document ends with `error` or `failure` status, instead of returning the failed document.
* **`Document.generate!` polling** — `Document.generate!` now sleeps `poll_interval` seconds (default 0.5s) between status polls instead of busy-looping.
* **`document_template_id` validation** — `Document.generate!`, `Document.generate`, and `Document.create_draft` now raise `ArgumentError` when `document_template_id` is missing or blank.
* **Removing `ostruct` dependency** — Attributes are now backed by `Struct` instead of `OpenStruct`. This removes the runtime dependency on the `ostruct` gem.
* **`Document#attributes` is no longer public** — Access individual attributes through their accessor methods instead.
* **`User-Agent` is no longer configurable** — The `user_agent` configuration option has been removed. The header is now always `pdfmonkey-ruby/<version>`.
* **`to_json` omits nil attributes** — `Resource#to_json` now compacts nil values and strips the `errors` attribute from the serialized output.
* **Resource base class** — All resource classes now inherit from `Pdfmonkey::Resource` which provides shared CRUD operations, attribute management and JSON serialization.

### New features

* Adding `Document#generate` and `Document#generate!` instance methods for triggering generation on draft documents
* Adding `Document#save` as a public method (was private in 0.9.0)
* Adding `Document.create_draft` for creating draft documents with preview support
* Adding `Document#update!` for updating document attributes via PUT
* Adding `Document.list_cards`, `Document.fetch_card`, and `Document.fetch_full` for accessing documents through the `Document` class
* Adding `output_type` to `Document` attributes
* Adding resources for:
  * `Engine`
  * `Snippet`
  * `TemplateCard`
  * `TemplateFolder`
  * `Template`
  * `Webhook`
  * `Workspace` (read-only)
* Adding `CurrentUser.fetch` for retrieving authenticated user info
* Adding `Pdfmonkey.with_adapter` for per-request adapter scoping (e.g. multi-tenant credentials)
* Adding persistent HTTP connections with configurable timeouts (`open_timeout`, `read_timeout`, `keep_alive_timeout`)
* Adding API key validation at request time (raises `Pdfmonkey::Error` if unconfigured)

## 0.9.0

* Testing against Ruby 3.2, 3.3 and 3.4
* Adding a Dependabot configuration file
* Adding ostruct as a runtime dependency in preparation of Ruby 3.5
* Bumping rake from 13.0.6 to 13.2.1
* Bumping rexml from 3.2.5 to 3.3.9
* Bumping rspec from 3.11 to 3.13
* Bumping actions/checkout from 3 to 4

## 0.8.1

* Fixing the handling of validation errors to expose errors correctly

## 0.8.0

* Adding support for single error responses

## 0.7.0

* Updating bundler to v2.2
* Adding `failure_cause`, `generation_logs` and `public_share_link` to the `Document` class

## 0.6.0

* Making the request `User-Agent` header configurable

## 0.5.0

* Adding `Document#filename`
* Adding `Document.delete` and `Document#delete!`

## 0.4.0

* Adding meta to `Document.generate!` and `Document.generate`
* Fixing the errors extraction to conform to the current API format
* Adding `Document.fetch` to retrieve a document

## 0.3.0

* Adding `Document#done?` to check if a document is complete

## 0.2.0

* Handling HTTP and API errors and exposing the error messages
