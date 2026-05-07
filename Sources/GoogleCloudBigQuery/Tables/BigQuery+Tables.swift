import RetryableTask
import Tracing

extension BigQuery {

  /// Lists all tables in a dataset.
  ///
  /// - Parameters:
  ///   - datasetID: The ID of the dataset to list tables from.
  /// - Returns: An array of ``TableInfo`` describing each table in the dataset.
  public func listTables(
    datasetID: String,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) async throws -> [TableInfo] {
    try await withSpan("bigquery-list-tables", ofKind: .client) { span in
      span.attributes["bigquery/dataset"] = datasetID

      var tables: [TableInfo] = []
      var pageToken: String? = nil

      repeat {
        var path = "/datasets/\(datasetID)/tables"
        if let token = pageToken {
          path += "?pageToken=\(token)"
        }

        let page: Google_Cloud_Bigquery_V2_TableList = try await withRetryableTask(
          logger: logger,
          operation: { try await request(method: .GET, path: path) },
          file: file,
          function: function,
          line: line
        )

        tables += page.tables.map(TableInfo.init)
        pageToken = page.nextPageToken.isEmpty ? nil : page.nextPageToken
      } while pageToken != nil

      return tables
    }
  }
}

/// Metadata for a table returned by ``BigQuery/listTables(datasetID:)``.
public struct TableInfo: Sendable, Equatable {

  /// The type of a BigQuery table.
  public enum TableType: String, Sendable, Equatable {
    case table = "TABLE"
    case view = "VIEW"
    case external = "EXTERNAL"
    case snapshot = "SNAPSHOT"
  }

  /// The ID of the table.
  public var tableID: String

  /// The ID of the dataset the table belongs to.
  public var datasetID: String

  /// The type of the table.
  public var type: TableType?

  /// The user-friendly name for the table, if one has been set.
  public var friendlyName: String?

  public init(tableID: String, datasetID: String, type: TableType? = nil, friendlyName: String? = nil) {
    self.tableID = tableID
    self.datasetID = datasetID
    self.type = type
    self.friendlyName = friendlyName
  }

  init(_ proto: Google_Cloud_Bigquery_V2_ListFormatTable) {
    self.tableID = proto.tableReference.tableID
    self.datasetID = proto.tableReference.datasetID
    self.type = TableType(rawValue: proto.type)
    self.friendlyName = proto.hasFriendlyName ? proto.friendlyName.value : nil
  }
}
