abstract class FundCloudStore {
  Future<String?> fetchRelatedSector(String fundCode);

  Future<String?> fetchSecidByRelatedSector(String relatedSector);

  Future<List<Map<String, dynamic>>?> analyzeFundText(String text);
}
