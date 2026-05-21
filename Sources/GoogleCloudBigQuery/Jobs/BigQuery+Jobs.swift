import RetryableTask
import Tracing

#if canImport(Foundation)
  import class Foundation.DateFormatter
#endif

extension BigQuery {

  public enum QueryError: Error {
    /// Job was not completed within the given timeout.
    case jobNotYetComplete
  }

  /// Executes a query against BigQuery and returns the results.
  ///
  /// - Parameters:
  ///   - query: The SQL query to execute
  ///   - type: The type to decode the results into. Must conform to `Decodable`.
  ///   - location: The geographic location where the job should run. For more information: https://cloud.google.com/bigquery/docs/locations#specify_locations
  /// - Returns: A `QueryResult` containing the decoded rows.
  public func query<Row: Decodable>(
    _ query: Query,
    as type: Row.Type = Row.self,
    location: String?,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) async throws -> QueryResult<Row> {
    try await self.query(
      query,
      location: location,
      map: { response in
        let decoder = RowDecoder()
        let rows: [Row] = try response.rows.map {
          try decoder.decode(Row.self, from: $0, schema: response.schema)
        }
        return QueryResult(
          rows: rows,
          totalRows: response.totalRows.value,
          affectedRows: response.numDmlAffectedRows.value,
          totalBytesProcessed: response.hasTotalBytesProcessed
            ? Int64(response.totalBytesProcessed.value) : nil,
          cacheHit: response.hasCacheHit ? response.cacheHit.value : nil,
          jobID: (response.hasJobReference && !response.jobReference.jobID.isEmpty)
            ? response.jobReference.jobID : nil
        )
      },
      file: file,
      function: function,
      line: line
    )
  }

  /// Executes a query against BigQuery and returns the results. Location to run is inferred from the application.
  ///
  /// - Parameters:
  ///   - query: The SQL query to execute
  ///   - type: The type to decode the results into. Must conform to `Decodable`.
  /// - Returns: A `QueryResult` containing the decoded rows.
  public func query<Row: Decodable>(
    _ query: Query,
    as type: Row.Type = Row.self,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) async throws -> QueryResult<Row> {
    let serviceContext = ServiceContext.current ?? .topLevel
    return try await self.query(
      query,
      as: type,
      location: await serviceContext.locationID,
      file: file,
      function: function,
      line: line
    )
  }

  /// Executes a query against BigQuery and returns the results.
  ///
  /// - Parameters:
  ///   - query: The SQL query to execute
  ///   - location: The geographic location where the job should run. For more information: https://cloud.google.com/bigquery/docs/locations#specify_locations
  /// - Returns: A `QueryResultMeta` containing the metadata.
  @discardableResult public func query(
    _ query: Query,
    location: String?,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) async throws -> QueryResultMeta {
    try await self.query(
      query,
      location: location,
      map: { response in
        QueryResultMeta(
          totalRows: response.totalRows.value,
          affectedRows: response.numDmlAffectedRows.value,
          totalBytesProcessed: response.hasTotalBytesProcessed
            ? Int64(response.totalBytesProcessed.value) : nil,
          cacheHit: response.hasCacheHit ? response.cacheHit.value : nil,
          jobID: (response.hasJobReference && !response.jobReference.jobID.isEmpty)
            ? response.jobReference.jobID : nil
        )
      },
      file: file,
      function: function,
      line: line
    )
  }

  /// Executes a query against BigQuery and returns the results. Location to run is inferred from the application.
  ///
  /// - Parameters:
  ///   - query: The SQL query to execute
  /// - Returns: A `QueryResultMeta` containing the metadata.
  @discardableResult public func query(
    _ query: Query,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) async throws -> QueryResultMeta {
    try await self.query(
      query,
      location: nil,
      file: file,
      function: function,
      line: line
    )
  }

  private func query<Result>(
    _ query: Query,
    location: String?,
    map: (Google_Cloud_Bigquery_V2_QueryResponse) throws -> Result,
    file: String,
    function: String,
    line: UInt
  ) async throws -> Result {
    try await withSpan("bigquery-query", ofKind: .client) { span in
      span.attributes["bigquery/query"] = query.sql

      // Execute query
      let response: Google_Cloud_Bigquery_V2_QueryResponse = try await withRetryableTask(
        logger: logger,
        operation: {
          try await request(
            method: .POST, path: "/queries",
            body: Google_Cloud_Bigquery_V2_QueryRequest.with {
              $0.query = query.sql
              if !query.parameters.isEmpty {
                $0.parameterMode = "POSITIONAL"
                $0.queryParameters = query.parameters.map(encode)
              }
              if let maxResults = query.maxResults {
                $0.maxResults = .with {
                  $0.value = maxResults
                }
              }
              $0.useLegacySql = false
              $0.jobCreationMode = .jobCreationOptional
              if let location {
                $0.location = location
              }
            })
        }, file: file, function: function, line: line)

      // Enrich the span with metadata returned by BigQuery so callers
      // can correlate slow / expensive queries with the actual BQ job
      // in the GCP console without an extra round trip. Attribute
      // names use the existing slash style for in-package consistency
      // with `bigquery/query` above.
      if response.hasJobReference {
        let ref = response.jobReference
        if !ref.jobID.isEmpty {
          span.attributes["bigquery/job_id"] = ref.jobID
        }
        if !ref.projectID.isEmpty {
          span.attributes["bigquery/project_id"] = ref.projectID
        }
        // `location` is a Google_Protobuf_StringValue wrapper —
        // optional in the proto, so guard with `hasLocation` and
        // unwrap via `.value`.
        if ref.hasLocation, !ref.location.value.isEmpty {
          span.attributes["bigquery/job_location"] = ref.location.value
        }
      }
      if response.hasTotalBytesProcessed {
        span.attributes["bigquery/total_bytes_processed"] = Int(response.totalBytesProcessed.value)
      }
      if response.hasCacheHit {
        span.attributes["bigquery/cache_hit"] = response.cacheHit.value
      }
      span.attributes["bigquery/job_complete"] = response.jobComplete.value

      span.addEvent("received")

      // Check if done
      guard response.jobComplete.value else {
        throw QueryError.jobNotYetComplete  // TODO: Maybe we should wait for it to finish?
      }
      return try map(response)
    }
  }

  private func encode(parameter: BigQueryValue) -> Google_Cloud_Bigquery_V2_QueryParameter {
    return .with {
      $0.parameterType = encode(parameterType: parameter.type)
      $0.parameterValue = encode(parameterValue: parameter.storage)
    }
  }

  private func encode(parameterValue value: BigQueryValue.Storage)
    -> Google_Cloud_Bigquery_V2_QueryParameterValue
  {
    switch value {
    case .string(let value):
      return .with {
        if let value {
          $0.value = .with {
            $0.value = value
          }
        }
      }
    case .bool(let value):
      return .with {
        if let value {
          $0.value = .with {
            $0.value = value ? "TRUE" : "FALSE"
          }
        }
      }
    case .int64(let value):
      return .with {
        if let value {
          $0.value = .with {
            $0.value = String(value)
          }
        }
      }
    case .float64(let value):
      return .with {
        if let value {
          $0.value = .with {
            $0.value = String(value)
          }
        }
      }
    #if canImport(Foundation)
      case .timestamp(let value):
        return .with {
          if let value {
            $0.value = .with {
              $0.value = DateFormatter.bigQuery.string(from: value)
            }
          }
        }
    #endif
    case .array(let values):
      return .with {
        $0.arrayValues = values.map { encode(parameterValue: $0.storage) }
      }
    case .struct(let values):
      return .with {
        if let values {
          $0.structValues = Dictionary(
            uniqueKeysWithValues: values.mapValues { encode(parameterValue: $0.storage) }.map {
              key, value in
              (key, value)
            })
        }
      }
    }
  }

  private func encode(parameterType type: BigQueryType)
    -> Google_Cloud_Bigquery_V2_QueryParameterType
  {
    return .with {
      $0.type = type.stringRepresentation
      switch type {
      case .array(let elementType):
        $0.arrayType = encode(parameterType: elementType)
      case .struct(let elementType):
        $0.structTypes = elementType.map { key, value in
          .with {
            $0.name = key
            $0.type = encode(parameterType: value)
          }
        }
      default:
        break
      }
    }
  }
}
