# Changelog

## HEAD

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
