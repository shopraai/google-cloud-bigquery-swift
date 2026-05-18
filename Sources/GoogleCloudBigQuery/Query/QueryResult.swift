public protocol QueryResultProtocol {

  /// The total number of rows in the result set.
  var totalRows: UInt64 { get }

  /// The number of rows affected (inserted, updated, and/or deleted) by the query.
  var affectedRows: Int64 { get }
}

/// The result of a query against BigQuery, with decoded rows.
public struct QueryResult<Row: Decodable>: QueryResultProtocol {

  /// The rows returned by the query.
  public let rows: [Row]

  /// The total number of rows in the result set.
  public let totalRows: UInt64

  /// The number of rows affected (inserted, updated, and/or deleted) by the query.
  public let affectedRows: Int64

  /// The total number of bytes processed by the query. Useful for cost
  /// attribution on on-demand pricing. `nil` if BigQuery did not report
  /// it (e.g., certain dry-run or fast-path query types).
  public let totalBytesProcessed: Int64?

  /// Whether the query was served from BigQuery's result cache. `nil`
  /// if BigQuery did not report it.
  public let cacheHit: Bool?

  /// The ID of the BigQuery job that ran this query, usable for
  /// cross-referencing in the GCP console. `nil` when no job was
  /// created (e.g., `job_creation_mode == JOB_CREATION_OPTIONAL` and
  /// the query completed without one).
  public let jobID: String?

  /// Memberwise init kept explicit (rather than letting Swift
  /// synthesize one) so the response-metadata fields can default to
  /// `nil` — existing call sites that only pass `rows` / `totalRows` /
  /// `affectedRows` continue to compile unchanged.
  public init(
    rows: [Row],
    totalRows: UInt64,
    affectedRows: Int64,
    totalBytesProcessed: Int64? = nil,
    cacheHit: Bool? = nil,
    jobID: String? = nil
  ) {
    self.rows = rows
    self.totalRows = totalRows
    self.affectedRows = affectedRows
    self.totalBytesProcessed = totalBytesProcessed
    self.cacheHit = cacheHit
    self.jobID = jobID
  }
}

/// The result of a query against BigQuery, without any rows.
public struct QueryResultMeta: QueryResultProtocol {

  /// The total number of rows in the result set.
  public let totalRows: UInt64

  /// The number of rows affected (inserted, updated, and/or deleted) by the query.
  public let affectedRows: Int64

  /// The total number of bytes processed by the query. Useful for cost
  /// attribution on on-demand pricing. `nil` if BigQuery did not report
  /// it.
  public let totalBytesProcessed: Int64?

  /// Whether the query was served from BigQuery's result cache. `nil`
  /// if BigQuery did not report it.
  public let cacheHit: Bool?

  /// The ID of the BigQuery job that ran this query, usable for
  /// cross-referencing in the GCP console. `nil` when no job was
  /// created.
  public let jobID: String?

  /// Memberwise init kept explicit so the response-metadata fields can
  /// default to `nil` — existing call sites that only pass `totalRows`
  /// / `affectedRows` continue to compile unchanged.
  public init(
    totalRows: UInt64,
    affectedRows: Int64,
    totalBytesProcessed: Int64? = nil,
    cacheHit: Bool? = nil,
    jobID: String? = nil
  ) {
    self.totalRows = totalRows
    self.affectedRows = affectedRows
    self.totalBytesProcessed = totalBytesProcessed
    self.cacheHit = cacheHit
    self.jobID = jobID
  }
}
