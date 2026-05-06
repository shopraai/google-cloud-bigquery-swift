import Testing

@testable import GoogleCloudBigQuery

@Suite struct LoadJobConfigurationTests {

    // MARK: - Default initialization

    @Test func defaultInitialization() {
        let config = LoadJobConfiguration()
        #expect(config.sourceFormat == .csv)
        #expect(config.writeDisposition == .append)
        #expect(config.createDisposition == .ifNeeded)
        #expect(config.autodetect == false)
    }

    // MARK: - Custom initialization

    @Test func customInitialization() {
        let config = LoadJobConfiguration(
            sourceFormat: .parquet,
            writeDisposition: .truncate,
            createDisposition: .never,
            autodetect: true
        )
        #expect(config.sourceFormat == .parquet)
        #expect(config.writeDisposition == .truncate)
        #expect(config.createDisposition == .never)
        #expect(config.autodetect == true)
    }

    // MARK: - SourceFormat protobuf string mappings

    @Test func sourceFormatRawValues() {
        #expect(LoadJobConfiguration.SourceFormat.csv.rawValue == "CSV")
        #expect(LoadJobConfiguration.SourceFormat.newlineDelimitedJSON.rawValue == "NEWLINE_DELIMITED_JSON")
        #expect(LoadJobConfiguration.SourceFormat.avro.rawValue == "AVRO")
        #expect(LoadJobConfiguration.SourceFormat.parquet.rawValue == "PARQUET")
        #expect(LoadJobConfiguration.SourceFormat.orc.rawValue == "ORC")
        #expect(LoadJobConfiguration.SourceFormat.datastoreBackup.rawValue == "DATASTORE_BACKUP")
    }

    // MARK: - WriteDisposition protobuf string mappings

    @Test func writeDispositionRawValues() {
        #expect(LoadJobConfiguration.WriteDisposition.append.rawValue == "WRITE_APPEND")
        #expect(LoadJobConfiguration.WriteDisposition.truncate.rawValue == "WRITE_TRUNCATE")
        #expect(LoadJobConfiguration.WriteDisposition.empty.rawValue == "WRITE_EMPTY")
    }

    // MARK: - CreateDisposition protobuf string mappings

    @Test func createDispositionRawValues() {
        #expect(LoadJobConfiguration.CreateDisposition.ifNeeded.rawValue == "CREATE_IF_NEEDED")
        #expect(LoadJobConfiguration.CreateDisposition.never.rawValue == "CREATE_NEVER")
    }

    // MARK: - Mutation

    @Test func isMutable() {
        var config = LoadJobConfiguration()
        config.sourceFormat = .avro
        config.writeDisposition = .empty
        config.createDisposition = .never
        config.autodetect = true
        #expect(config.sourceFormat == .avro)
        #expect(config.writeDisposition == .empty)
        #expect(config.createDisposition == .never)
        #expect(config.autodetect == true)
    }

    // MARK: - CSV options

    @Test func csvOptionsDefaultNil() {
        let config = LoadJobConfiguration()
        #expect(config.skipLeadingRows == nil)
        #expect(config.allowQuotedNewlines == nil)
        #expect(config.maxBadRecords == nil)
    }

    @Test func csvOptionsViaInit() {
        let config = LoadJobConfiguration(
            sourceFormat: .csv,
            skipLeadingRows: 1,
            allowQuotedNewlines: true,
            maxBadRecords: 5
        )
        #expect(config.skipLeadingRows == 1)
        #expect(config.allowQuotedNewlines == true)
        #expect(config.maxBadRecords == 5)
    }

    @Test func csvOptionsViaSchemaInit() {
        let schema = BigQuerySchema(fields: [.init(name: "id", type: .string)])
        let config = LoadJobConfiguration(
            sourceFormat: .csv,
            schema: schema,
            skipLeadingRows: 1,
            allowQuotedNewlines: false,
            maxBadRecords: 0
        )
        #expect(config.autodetect == false)
        #expect(config.schema?.fields.count == 1)
        #expect(config.skipLeadingRows == 1)
        #expect(config.allowQuotedNewlines == false)
        #expect(config.maxBadRecords == 0)
    }

    @Test func csvOptionsAreMutable() {
        var config = LoadJobConfiguration()
        config.skipLeadingRows = 2
        config.allowQuotedNewlines = true
        config.maxBadRecords = 10
        #expect(config.skipLeadingRows == 2)
        #expect(config.allowQuotedNewlines == true)
        #expect(config.maxBadRecords == 10)
    }
}

@Suite struct LoadDestinationTests {

    @Test func initialization() {
        let dest = LoadDestination(datasetID: "my_dataset", tableID: "my_table")
        #expect(dest.datasetID == "my_dataset")
        #expect(dest.tableID == "my_table")
    }

    @Test func isMutable() {
        var dest = LoadDestination(datasetID: "original_dataset", tableID: "original_table")
        dest.datasetID = "new_dataset"
        dest.tableID = "new_table"
        #expect(dest.datasetID == "new_dataset")
        #expect(dest.tableID == "new_table")
    }
}
