# Changelog

## Unreleased

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
