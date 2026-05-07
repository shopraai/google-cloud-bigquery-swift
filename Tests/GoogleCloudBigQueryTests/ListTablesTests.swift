import Testing

@testable import GoogleCloudBigQuery

@Suite struct TableInfoTests {

  // MARK: - Initialization

  @Test func initialization() {
    let info = TableInfo(tableID: "my_table", datasetID: "my_dataset")
    #expect(info.tableID == "my_table")
    #expect(info.datasetID == "my_dataset")
    #expect(info.type == nil)
    #expect(info.friendlyName == nil)
  }

  @Test func initializationWithAllFields() {
    let info = TableInfo(
      tableID: "my_table",
      datasetID: "my_dataset",
      type: .table,
      friendlyName: "My Table"
    )
    #expect(info.tableID == "my_table")
    #expect(info.datasetID == "my_dataset")
    #expect(info.type == .table)
    #expect(info.friendlyName == "My Table")
  }

  // MARK: - Mutation

  @Test func isMutable() {
    var info = TableInfo(tableID: "original_table", datasetID: "original_dataset")
    info.tableID = "new_table"
    info.datasetID = "new_dataset"
    info.type = .view
    info.friendlyName = "New Table"
    #expect(info.tableID == "new_table")
    #expect(info.datasetID == "new_dataset")
    #expect(info.type == .view)
    #expect(info.friendlyName == "New Table")
  }

  // MARK: - TableType raw values

  @Test func tableTypeRawValues() {
    #expect(TableInfo.TableType.table.rawValue == "TABLE")
    #expect(TableInfo.TableType.view.rawValue == "VIEW")
    #expect(TableInfo.TableType.external.rawValue == "EXTERNAL")
    #expect(TableInfo.TableType.snapshot.rawValue == "SNAPSHOT")
  }

  @Test func tableTypeFromRawValue() {
    #expect(TableInfo.TableType(rawValue: "TABLE") == .table)
    #expect(TableInfo.TableType(rawValue: "VIEW") == .view)
    #expect(TableInfo.TableType(rawValue: "EXTERNAL") == .external)
    #expect(TableInfo.TableType(rawValue: "SNAPSHOT") == .snapshot)
    #expect(TableInfo.TableType(rawValue: "UNKNOWN") == nil)
  }

  // MARK: - Equatable

  @Test func equality() {
    let a = TableInfo(tableID: "t", datasetID: "d", type: .table, friendlyName: "T")
    let b = TableInfo(tableID: "t", datasetID: "d", type: .table, friendlyName: "T")
    #expect(a == b)
  }

  @Test func inequality() {
    let a = TableInfo(tableID: "t1", datasetID: "d")
    let b = TableInfo(tableID: "t2", datasetID: "d")
    #expect(a != b)
  }
}
