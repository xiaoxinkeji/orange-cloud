//
//  CFAPIResponseTests.swift
//  Orange CloudTests
//
//  Tests for CFAPIResponse / CFAPIResponseArray JSON decoding and error conversion.
//

import XCTest
@testable import Orange_Cloud

final class CFAPIResponseTests: XCTestCase {

    // MARK: - Successful single-result response

    func testDecodeSuccessfulResponse() throws {
        let json = """
        {
            "result": {
                "id": "zone-123",
                "name": "example.com",
                "status": "active",
                "plan": { "name": "free" },
                "name_servers": ["ns1.cf.com", "ns2.cf.com"]
            },
            "success": true,
            "errors": [],
            "messages": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponse<Zone>.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertTrue(response.errors.isEmpty)
        XCTAssertNotNil(response.result)
        XCTAssertEqual(response.result?.name, "example.com")
        XCTAssertEqual(response.result?.id, "zone-123")
    }

    // MARK: - Error response

    func testDecodeErrorResponse() throws {
        let json = """
        {
            "result": null,
            "success": false,
            "errors": [
                { "code": 9109, "message": "Invalid access token" }
            ],
            "messages": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponse<Zone>.self, from: json)

        XCTAssertFalse(response.success)
        XCTAssertNil(response.result)
        XCTAssertEqual(response.errors.count, 1)
        XCTAssertEqual(response.errors.first?.code, 9109)
        XCTAssertEqual(response.errors.first?.message, "Invalid access token")
    }

    // MARK: - Missing optional fields (messages is optional)

    func testDecodeWithMissingMessages() throws {
        let json = """
        {
            "result": null,
            "success": true,
            "errors": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponse<EmptyResponse>.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertNil(response.messages)
    }

    // MARK: - toAPIError() conversion

    func testToAPIError_withErrors() throws {
        let json = """
        {
            "result": null,
            "success": false,
            "errors": [
                { "code": 1000, "message": "DNS validation error" }
            ],
            "messages": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponse<EmptyResponse>.self, from: json)
        let apiError = response.toAPIError()

        if case .cloudflareError(let code, let message) = apiError {
            XCTAssertEqual(code, 1000)
            XCTAssertEqual(message, "DNS validation error")
        } else {
            XCTFail("Expected .cloudflareError, got \(apiError)")
        }
    }

    func testToAPIError_withEmptyErrors() throws {
        let json = """
        {
            "result": null,
            "success": false,
            "errors": [],
            "messages": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponse<EmptyResponse>.self, from: json)
        let apiError = response.toAPIError()

        // When errors array is empty, code defaults to 0
        if case .cloudflareError(let code, _) = apiError {
            XCTAssertEqual(code, 0)
        } else {
            XCTFail("Expected .cloudflareError, got \(apiError)")
        }
    }

    // MARK: - CFAPIResponseArray: paginated response with result_info

    func testDecodeArrayResponseWithPagination() throws {
        let json = """
        {
            "result": [
                {
                    "id": "zone-1",
                    "name": "one.com",
                    "status": "active",
                    "plan": { "name": "free" }
                },
                {
                    "id": "zone-2",
                    "name": "two.com",
                    "status": "active",
                    "plan": { "name": "pro" }
                }
            ],
            "success": true,
            "errors": [],
            "result_info": {
                "page": 1,
                "per_page": 20,
                "total_pages": 3,
                "count": 2,
                "total_count": 42
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponseArray<Zone>.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.result?.count, 2)
        XCTAssertEqual(response.result?[0].name, "one.com")
        XCTAssertEqual(response.result?[1].name, "two.com")

        XCTAssertNotNil(response.resultInfo)
        XCTAssertEqual(response.resultInfo?.page, 1)
        XCTAssertEqual(response.resultInfo?.perPage, 20)
        XCTAssertEqual(response.resultInfo?.totalPages, 3)
        XCTAssertEqual(response.resultInfo?.count, 2)
        XCTAssertEqual(response.resultInfo?.totalCount, 42)
    }

    // MARK: - Cursor-based pagination (R2 / KV)

    func testDecodeArrayResponseWithCursor() throws {
        let json = """
        {
            "result": [],
            "success": true,
            "errors": [],
            "result_info": {
                "cursor": "eyJhZnRlciI6InNvbWVrZXkifQ==",
                "is_truncated": true
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponseArray<EmptyResponse>.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.result?.count, 0)
        XCTAssertEqual(response.resultInfo?.cursor, "eyJhZnRlciI6InNvbWVrZXkifQ==")
        XCTAssertEqual(response.resultInfo?.isTruncated, true)
    }

    // MARK: - Missing result_info

    func testDecodeArrayResponseWithoutResultInfo() throws {
        let json = """
        {
            "result": [
                {
                    "id": "zone-x",
                    "name": "x.com",
                    "status": "active"
                }
            ],
            "success": true,
            "errors": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponseArray<Zone>.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.result?.count, 1)
        XCTAssertNil(response.resultInfo)
    }

    // MARK: - CFAPIResponseArray toAPIError

    func testArrayToAPIError() throws {
        let json = """
        {
            "result": null,
            "success": false,
            "errors": [
                { "code": 6003, "message": "Invalid request headers" },
                { "code": 6004, "message": "Secondary error" }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponseArray<Zone>.self, from: json)
        let apiError = response.toAPIError()

        // toAPIError uses the first error
        if case .cloudflareError(let code, let message) = apiError {
            XCTAssertEqual(code, 6003)
            XCTAssertEqual(message, "Invalid request headers")
        } else {
            XCTFail("Expected .cloudflareError, got \(apiError)")
        }
    }

    // MARK: - EmptyResponse decoding (for DELETE requests)

    func testDecodeEmptyResponse() throws {
        let json = """
        {
            "result": {},
            "success": true,
            "errors": [],
            "messages": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponse<EmptyResponse>.self, from: json)
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.result)
    }

    // MARK: - Multiple errors in response

    func testDecodeMultipleErrors() throws {
        let json = """
        {
            "result": null,
            "success": false,
            "errors": [
                { "code": 1001, "message": "First error" },
                { "code": 1002, "message": "Second error" },
                { "code": 1003, "message": "Third error" }
            ],
            "messages": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CFAPIResponse<EmptyResponse>.self, from: json)
        XCTAssertEqual(response.errors.count, 3)
        XCTAssertEqual(response.errors[0].code, 1001)
        XCTAssertEqual(response.errors[1].code, 1002)
        XCTAssertEqual(response.errors[2].code, 1003)
    }
}
