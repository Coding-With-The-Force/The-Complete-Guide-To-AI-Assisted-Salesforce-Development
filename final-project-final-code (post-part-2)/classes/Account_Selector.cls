/**
 * Created by gerry on 5/2/2021.
 */

public with sharing class Account_Selector extends fflib_SObjectSelector
{
	public List<Schema.SObjectField> getSObjectFieldList(){
		return new List<Schema.SObjectField>{
				Account.Id,
				Account.Name,
				Account.Description
		};
	}

	public Schema.SObjectType getSObjectType(){
		return Account.SObjectType;
	}

	public override String getOrderBy(){
		return 'Description';
	}

	public List<Account> selectById(Set<Id> accountIds){
		return (List<Account>) selectSObjectsById(accountIds);
	}

	/**
	 * @description Selects accounts with geolocation data (non-null shipping coordinates)
	 * @param limitSize Maximum number of records to return
	 * @return List of Account records with geolocation fields
	 */
	public List<Account> selectWithGeolocation(Integer limitSize) {
		return (List<Account>) Database.query(
			newQueryFactory()
				.selectField(Account.AnnualRevenue)
				.selectField(Account.Phone)
				.selectField(Account.ShippingLatitude)
				.selectField(Account.ShippingLongitude)
				.selectField(Account.ShippingStreet)
				.selectField(Account.ShippingCity)
				.selectField(Account.ShippingState)
				.selectField(Account.ShippingPostalCode)
				.selectField(Account.ShippingCountry)
				.setCondition('ShippingLatitude != null AND ShippingLongitude != null')
				.setOrdering(Account.Name, fflib_QueryFactory.SortOrder.ASCENDING)
				.setLimit(limitSize)
				.toSOQL()
		);
	}

	/**
	 * @description Selects accounts by shipping state with geolocation data
	 * @param state The state abbreviation or name to filter by
	 * @param limitSize Maximum number of records to return
	 * @return List of Account records in the specified state
	 */
	public List<Account> selectByState(String state, Integer limitSize) {
		return (List<Account>) Database.query(
			newQueryFactory()
				.selectField(Account.AnnualRevenue)
				.selectField(Account.Phone)
				.selectField(Account.ShippingLatitude)
				.selectField(Account.ShippingLongitude)
				.selectField(Account.ShippingStreet)
				.selectField(Account.ShippingCity)
				.selectField(Account.ShippingState)
				.selectField(Account.ShippingPostalCode)
				.selectField(Account.ShippingCountry)
				.setCondition('ShippingState = :state AND ShippingLatitude != null AND ShippingLongitude != null')
				.setOrdering(Account.Name, fflib_QueryFactory.SortOrder.ASCENDING)
				.setLimit(limitSize)
				.toSOQL()
		);
	}

	/**
	 * @description Selects accounts by shipping postal code with geolocation data
	 * @param postalCode The postal code to filter by
	 * @param limitSize Maximum number of records to return
	 * @return List of Account records with the specified postal code
	 */
	public List<Account> selectByPostalCode(String postalCode, Integer limitSize) {
		return (List<Account>) Database.query(
			newQueryFactory()
				.selectField(Account.AnnualRevenue)
				.selectField(Account.Phone)
				.selectField(Account.ShippingLatitude)
				.selectField(Account.ShippingLongitude)
				.selectField(Account.ShippingStreet)
				.selectField(Account.ShippingCity)
				.selectField(Account.ShippingState)
				.selectField(Account.ShippingPostalCode)
				.selectField(Account.ShippingCountry)
				.setCondition('ShippingPostalCode = :postalCode AND ShippingLatitude != null AND ShippingLongitude != null')
				.setOrdering(Account.Name, fflib_QueryFactory.SortOrder.ASCENDING)
				.setLimit(limitSize)
				.toSOQL()
		);
	}

	/**
	 * @description Finds center account by name pattern for radius searches
	 * @param namePattern The name pattern to search for (will be used with LIKE)
	 * @return Single Account record matching the name pattern with geolocation
	 */
	public Account selectCenterAccountByNameLike(String namePattern) {
		List<Account> accounts = (List<Account>) Database.query(
			newQueryFactory()
				.selectField(Account.ShippingLatitude)
				.selectField(Account.ShippingLongitude)
				.setCondition('Name LIKE :namePattern AND ShippingLatitude != null AND ShippingLongitude != null')
				.setOrdering(Account.Name, fflib_QueryFactory.SortOrder.ASCENDING)
				.setLimit(1)
				.toSOQL()
		);
		return accounts.isEmpty() ? null : accounts[0];
	}

	/**
	 * @description Selects accounts within specified distance from coordinates using DISTANCE function
	 * @param centerLatitude Center point latitude
	 * @param centerLongitude Center point longitude  
	 * @param radiusMiles Search radius in miles
	 * @return List of Account records within the specified radius
	 */
	public List<Account> selectNearLocation(Decimal centerLatitude, Decimal centerLongitude, Decimal radiusMiles) {
		String distanceCondition = 'ShippingLatitude != null AND ShippingLongitude != null AND DISTANCE(ShippingAddress, GEOLOCATION(' + centerLatitude + ', ' + centerLongitude + '), \'mi\') < ' + radiusMiles;
		String distanceOrdering = 'DISTANCE(ShippingAddress, GEOLOCATION(' + centerLatitude + ', ' + centerLongitude + '), \'mi\')';

		// Note: fflib_QueryFactory doesn't support DISTANCE functions directly, so we build the query manually
		String query = 'SELECT ' + String.join(getSObjectFieldList(), ', ') + 
					   ', AnnualRevenue, Phone, ShippingLatitude, ShippingLongitude, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry' +
					   ' FROM Account' +
					   ' WHERE ' + distanceCondition +
					   ' ORDER BY ' + distanceOrdering +
					   ' LIMIT 500';
		
		return (List<Account>) Database.query(query);
	}
}