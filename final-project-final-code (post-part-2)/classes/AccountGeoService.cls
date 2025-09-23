/**
 * @description Service class for Account geolocation operations using Apex Common patterns
 * Handles retrieval and processing of Account records with geolocation data for map display
 * Implements security best practices including CRUD/FLS checks and input sanitization
 * Uses Service Factory pattern and delegates to Selector layer
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
    
    
    /**
     * @description Retrieves initial set of Account markers with geolocation data using Apex Common patterns
     * @param limitSize Maximum number of accounts to return (default 500)
     * @return List of AccountMapMarker objects for map display
     * @throws InvalidGeolocationException if no accounts with geolocation found
     */
    public List<AccountMapMarker> getInitialAccountMarkers(Integer limitSize) {
        if (limitSize == null || limitSize <= 0) {
            limitSize = 500;
        }
        
        Account_Selector accountSelector = getAccountSelector();
        List<Account> accounts = accountSelector.selectWithGeolocation(limitSize);
        accounts = enforceFieldSecurity(accounts);
        
        if (accounts.isEmpty()) {
            throw new InvalidGeolocationException('No accounts found with valid shipping coordinates');
        }
        
        return convertAccountsToMarkers(accounts);
    }

    /**
     * @description Retrieves Account markers filtered by state using Apex Common patterns
     * @param state The state abbreviation or name to filter by (sanitized)
     * @param limitSize Maximum number of accounts to return (default 500)
     * @return List of AccountMapMarker objects in the specified state
     * @throws InvalidGeolocationException if no accounts found in state
     */
    public List<AccountMapMarker> getAccountMarkersByState(String state, Integer limitSize) {
        String sanitizedState = sanitizeInput(state);
        
        if (limitSize == null || limitSize <= 0) {
            limitSize = 500;
        }
        
        Account_Selector accountSelector = getAccountSelector();
        List<Account> accounts = accountSelector.selectByState(sanitizedState, limitSize);
        accounts = enforceFieldSecurity(accounts);
        
        if (accounts.isEmpty()) {
            throw new InvalidGeolocationException('No accounts found in state: ' + sanitizedState);
        }
        
        return convertAccountsToMarkers(accounts);
    }

    /**
     * @description Retrieves Account markers filtered by postal code using Apex Common patterns
     * @param postalCode The postal code to filter by (sanitized)
     * @param limitSize Maximum number of accounts to return (default 500)
     * @return List of AccountMapMarker objects with the specified postal code
     * @throws InvalidGeolocationException if no accounts found with postal code
     */
    public List<AccountMapMarker> getAccountMarkersByPostalCode(String postalCode, Integer limitSize) {
        String sanitizedPostalCode = sanitizeInput(postalCode);
        
        if (limitSize == null || limitSize <= 0) {
            limitSize = 500;
        }
        
        Account_Selector accountSelector = getAccountSelector();
        List<Account> accounts = accountSelector.selectByPostalCode(sanitizedPostalCode, limitSize);
        accounts = enforceFieldSecurity(accounts);
        
        if (accounts.isEmpty()) {
            throw new InvalidGeolocationException('No accounts found with postal code: ' + sanitizedPostalCode);
        }
        
        return convertAccountsToMarkers(accounts);
    }
    
    /**
     * @description Retrieves Account markers within specified radius of a named account using Apex Common patterns
     * @param accountName The name of the center account (sanitized)
     * @param radiusMiles Radius in miles to search within (default 50)
     * @return List of AccountMapMarker objects within the specified radius
     * @throws NoCenterAccountFoundException if center account not found
     */
    public List<AccountMapMarker> getAccountMarkersNearAccountName(String accountName, Decimal radiusMiles) {
        String sanitizedAccountName = sanitizeInput(accountName);
        
        if (radiusMiles == null || radiusMiles <= 0) {
            radiusMiles = 50;
        }
        
        Account centerAccount = findCenterAccount(sanitizedAccountName);
        Account_Selector accountSelector = getAccountSelector();
        
        List<Account> nearbyAccounts = accountSelector.selectNearLocation(
            centerAccount.ShippingLatitude, 
            centerAccount.ShippingLongitude, 
            radiusMiles
        );
        nearbyAccounts = enforceFieldSecurity(nearbyAccounts);
        
        return convertAccountsToMarkers(nearbyAccounts);
    }

    /**
     * @description Gets Account_Selector instance from Application factory
     * @return Account_Selector instance
     */
    private Account_Selector getAccountSelector() {
        return (Account_Selector)Application.selector.newInstance(Account.SObjectType);
    }
    
    /**
     * @description Sanitizes user input to prevent SOQL injection and XSS
     * @param input The raw input string
     * @return Sanitized and escaped string safe for SOQL and display
     */
    private String sanitizeInput(String input) {
        if (String.isBlank(input)) {
            return '';
        }
        
        String escaped = String.escapeSingleQuotes(input.trim()).escapeHtml4();
        return escaped;
    }
    
    /**
     * @description Finds the center account by name for radius search using selector
     * @param sanitizedAccountName The sanitized account name to search for
     * @return Account record to use as center point
     * @throws NoCenterAccountFoundException if no matching account found
     */
    private Account findCenterAccount(String sanitizedAccountName) {
        String namePattern = '%' + sanitizedAccountName + '%';
        Account_Selector accountSelector = getAccountSelector();
        Account centerAccount = accountSelector.selectCenterAccountByNameLike(namePattern);
        
        if (centerAccount == null) {
            throw new NoCenterAccountFoundException('No account found with name containing: ' + sanitizedAccountName);
        }
        
        List<Account> accounts = new List<Account>{ centerAccount };
        accounts = enforceFieldSecurity(accounts);
        return accounts.isEmpty() ? null : accounts[0];
    }
    
    /**
     * @description Enforces field-level security using Security.stripInaccessible
     * @param accounts List of Account records to secure
     * @return List of Account records with inaccessible fields removed
     */
    private List<Account> enforceFieldSecurity(List<Account> accounts) {
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, accounts);
        return decision.getRecords();
    }
    
    /**
     * @description Converts Account records to AccountMapMarker objects
     * @param accounts List of Account records with geolocation data
     * @return List of AccountMapMarker objects for map display
     */
    private List<AccountMapMarker> convertAccountsToMarkers(List<Account> accounts) {
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
    private AccountMapMarker createMarkerFromAccount(Account acc) {
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
    private String buildMarkerDescription(Account acc) {
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
    private String formatCurrency(Decimal amount) {
        return String.valueOf(amount.setScale(0));
    }
    
    /**
     * @description Builds complete address string from Account shipping fields
     * @param acc Account record with shipping address fields
     * @return Formatted address string
     */
    private String buildAddressString(Account acc) {
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