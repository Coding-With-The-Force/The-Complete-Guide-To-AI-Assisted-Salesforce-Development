/**
 * @description Service class for Account geolocation operations
 * Handles retrieval and processing of Account records with geolocation data for map display
 * Implements security best practices including CRUD/FLS checks and input sanitization
 * 
 * @author System Administrator
 * @since 2025-01-21
 */
public with sharing class AccountGeoService {
    
    /**
     * @description Custom exception for cases where no center account is found
     */
    public class NoCenterAccountFoundException extends Exception {}
    
    /**
     * @description Custom exception for invalid geolocation data
     */
    public class InvalidGeolocationException extends Exception {}
    
    private static final String[] ACCOUNT_FIELDS = new String[] {
        'Id', 'Name', 'AnnualRevenue', 'Phone', 
        'ShippingLatitude', 'ShippingLongitude',
        'ShippingStreet', 'ShippingCity', 'ShippingState', 
        'ShippingPostalCode', 'ShippingCountry'
    };
    
    /**
     * @description Retrieves initial set of Account markers with geolocation data
     * @param limitSize Maximum number of accounts to return (default 500)
     * @return List of AccountMapMarker objects for map display
     * @throws InvalidGeolocationException if no accounts with geolocation found
     */
    public static List<AccountMapMarker> getInitialAccountMarkers(Integer limitSize) {
        if (limitSize == null || limitSize <= 0) {
            limitSize = 500;
        }
        
        List<Account> accounts = queryAccountsWithGeolocation(limitSize);
        
        if (accounts.isEmpty()) {
            throw new InvalidGeolocationException('No accounts found with valid shipping coordinates');
        }
        
        return convertAccountsToMarkers(accounts);
    }
    
    /**
     * @description Retrieves Account markers within specified radius of a named account
     * @param accountName The name of the center account (sanitized)
     * @param radiusMiles Radius in miles to search within (default 50)
     * @return List of AccountMapMarker objects within the specified radius
     * @throws NoCenterAccountFoundException if center account not found
     */
    public static List<AccountMapMarker> getAccountMarkersNearAccountName(String accountName, Decimal radiusMiles) {
        String sanitizedAccountName = sanitizeInput(accountName);
        
        if (radiusMiles == null || radiusMiles <= 0) {
            radiusMiles = 50;
        }
        
        Account centerAccount = findCenterAccount(sanitizedAccountName);
        
        List<Account> nearbyAccounts = queryAccountsNearLocation(
            centerAccount.ShippingLatitude, 
            centerAccount.ShippingLongitude, 
            radiusMiles
        );
        
        return convertAccountsToMarkers(nearbyAccounts);
    }
    
    /**
     * @description Sanitizes user input to prevent SOQL injection and XSS
     * @param input The raw input string
     * @return Sanitized and escaped string safe for SOQL and display
     */
    private static String sanitizeInput(String input) {
        if (String.isBlank(input)) {
            return '';
        }
        
        String escaped = String.escapeSingleQuotes(input.trim()).escapeHtml4();
        return escaped;
    }
    
    /**
     * @description Queries accounts with non-null geolocation data
     * @param limitSize Maximum number of records to return
     * @return List of Account records with geolocation data
     */
    private static List<Account> queryAccountsWithGeolocation(Integer limitSize) {
        String query = 'SELECT ' + String.join(ACCOUNT_FIELDS, ', ') + 
                      ' FROM Account ' + 
                      ' WHERE ShippingLatitude != null AND ShippingLongitude != null ' + 
                      ' ORDER BY Name ' + 
                      ' LIMIT :limitSize';
        
        List<Account> accounts = Database.query(query);
        
        return enforceFieldSecurity(accounts);
    }
    
    /**
     * @description Finds the center account by name for radius search
     * @param sanitizedAccountName The sanitized account name to search for
     * @return Account record to use as center point
     * @throws NoCenterAccountFoundException if no matching account found
     */
    private static Account findCenterAccount(String sanitizedAccountName) {
        String query = 'SELECT ' + String.join(ACCOUNT_FIELDS, ', ') + 
                      ' FROM Account ' + 
                      ' WHERE Name LIKE \'%' + sanitizedAccountName + '%\' ' +
                      ' AND ShippingLatitude != null AND ShippingLongitude != null ' + 
                      ' ORDER BY Name ' + 
                      ' LIMIT 1';
        
        List<Account> centerAccounts = Database.query(query);
        centerAccounts = enforceFieldSecurity(centerAccounts);
        
        if (centerAccounts.isEmpty()) {
            throw new NoCenterAccountFoundException('No account found with name containing: ' + sanitizedAccountName);
        }
        
        return centerAccounts[0];
    }
    
    /**
     * @description Queries accounts within specified distance from coordinates
     * @param centerLat Center latitude coordinate  
     * @param centerLon Center longitude coordinate
     * @param radiusMiles Search radius in miles
     * @return List of Account records within the specified radius
     */
    private static List<Account> queryAccountsNearLocation(Decimal centerLat, Decimal centerLon, Decimal radiusMiles) {
        String query = 'SELECT ' + String.join(ACCOUNT_FIELDS, ', ') + 
                      ' FROM Account ' + 
                      ' WHERE ShippingLatitude != null AND ShippingLongitude != null ' + 
                      ' AND DISTANCE(ShippingAddress, GEOLOCATION(:centerLat, :centerLon), \'mi\') < :radiusMiles ' +
                      ' ORDER BY DISTANCE(ShippingAddress, GEOLOCATION(:centerLat, :centerLon), \'mi\') ' + 
                      ' LIMIT 500';
        
        List<Account> accounts = Database.query(query);
        
        return enforceFieldSecurity(accounts);
    }
    
    /**
     * @description Enforces field-level security using Security.stripInaccessible
     * @param accounts List of Account records to secure
     * @return List of Account records with inaccessible fields removed
     */
    private static List<Account> enforceFieldSecurity(List<Account> accounts) {
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, accounts);
        return decision.getRecords();
    }
    
    /**
     * @description Converts Account records to AccountMapMarker objects
     * @param accounts List of Account records with geolocation data
     * @return List of AccountMapMarker objects for map display
     */
    private static List<AccountMapMarker> convertAccountsToMarkers(List<Account> accounts) {
        List<AccountMapMarker> markers = new List<AccountMapMarker>();
        
        for (Account acc : accounts) {
            AccountMapMarker marker = createMarkerFromAccount(acc);
            markers.add(marker);
        }
        
        return markers;
    }
    
    /**
     * @description Creates an AccountMapMarker from an Account record
     * @param acc The Account record to convert
     * @return AccountMapMarker with formatted description
     */
    private static AccountMapMarker createMarkerFromAccount(Account acc) {
        String description = buildMarkerDescription(acc);
        
        return new AccountMapMarker(
            acc.Id,
            acc.Name,
            acc.ShippingLatitude,
            acc.ShippingLongitude,
            description
        );
    }
    
    /**
     * @description Builds formatted description text for map marker
     * @param acc Account record containing the data
     * @return Formatted description string with account details
     */
    private static String buildMarkerDescription(Account acc) {
        List<String> descriptionParts = new List<String>();
        
        // Account Name
        if (String.isNotBlank(acc.Name)) {
            descriptionParts.add('Account: ' + acc.Name);
        }
        
        // Annual Revenue
        if (acc.AnnualRevenue != null) {
            descriptionParts.add('Annual Revenue: $' + formatCurrency(acc.AnnualRevenue));
        }
        
        // Phone
        if (String.isNotBlank(acc.Phone)) {
            descriptionParts.add('Phone: ' + acc.Phone);
        }
        
        // Address
        String address = buildAddressString(acc);
        if (String.isNotBlank(address)) {
            descriptionParts.add('Address: ' + address);
        }
        
        return String.join(descriptionParts, '\n');
    }
    
    /**
     * @description Formats currency value for display
     * @param amount Decimal amount to format
     * @return Formatted currency string
     */
    private static String formatCurrency(Decimal amount) {
        return String.valueOf(amount.setScale(0));
    }
    
    /**
     * @description Builds complete address string from Account shipping fields
     * @param acc Account record with shipping address fields
     * @return Formatted address string
     */
    private static String buildAddressString(Account acc) {
        List<String> addressParts = new List<String>();
        
        if (String.isNotBlank(acc.ShippingStreet)) {
            addressParts.add(acc.ShippingStreet);
        }
        
        List<String> cityStateZip = new List<String>();
        if (String.isNotBlank(acc.ShippingCity)) {
            cityStateZip.add(acc.ShippingCity);
        }
        if (String.isNotBlank(acc.ShippingState)) {
            cityStateZip.add(acc.ShippingState);
        }
        if (String.isNotBlank(acc.ShippingPostalCode)) {
            cityStateZip.add(acc.ShippingPostalCode);
        }
        
        if (!cityStateZip.isEmpty()) {
            addressParts.add(String.join(cityStateZip, ', '));
        }
        
        if (String.isNotBlank(acc.ShippingCountry)) {
            addressParts.add(acc.ShippingCountry);
        }
        
        return String.join(addressParts, ', ');
    }
}
