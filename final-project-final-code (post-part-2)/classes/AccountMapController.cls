/**
 * @description Controller class for Account Map Lightning Web Component
 * Provides AuraEnabled methods for retrieving account geolocation data
 * Follows Apex Common patterns with no business logic in controller methods
 * Uses Service Factory pattern and sanitizes input
 * 
 * @author System Administrator
 * @since 2025-01-21
 */
public with sharing class AccountMapController {
    
    private static final AccountGeoService service = (AccountGeoService)Application.service.newInstance(AccountGeoService.class);

    /**
     * @description Retrieves initial set of account markers for map display
     * @param limitSize Maximum number of accounts to return
     * @return List of AccountMapMarker objects for map display
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountMapMarker> getInitialMarkers(Integer limitSize) {
        try {
            return service.getInitialAccountMarkers(limitSize);
        } catch (AccountGeoService.InvalidGeolocationException e) {
            throw new AuraHandledException('Unable to load account markers: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getInitialMarkers: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred while loading account markers');
        }
    }
    
    /**
     * @description Retrieves account markers within specified radius of named account
     * @param accountName The name of the center account to search around
     * @param radiusMiles The search radius in miles
     * @return List of AccountMapMarker objects within the specified radius
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountMapMarker> getMarkersNearAccountName(String accountName, Decimal radiusMiles) {
        String sanitizedAccountName = sanitizeInput(accountName);
        
        try {
            return service.getAccountMarkersNearAccountName(sanitizedAccountName, radiusMiles);
        } catch (AccountGeoService.NoCenterAccountFoundException e) {
            throw new AuraHandledException('Account not found: ' + e.getMessage());
        } catch (AccountGeoService.InvalidGeolocationException e) {
            throw new AuraHandledException('Invalid location data: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getMarkersNearAccountName: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred while searching for nearby accounts');
        }
    }
    
    /**
     * @description Retrieves account markers filtered by state
     * @param state The state abbreviation or name to filter by
     * @param limitSize Maximum number of accounts to return
     * @return List of AccountMapMarker objects in the specified state
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountMapMarker> getMarkersByState(String state, Integer limitSize) {
        String sanitizedState = sanitizeInput(state);
        
        try {
            return service.getAccountMarkersByState(sanitizedState, limitSize);
        } catch (AccountGeoService.InvalidGeolocationException e) {
            throw new AuraHandledException('No accounts found: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getMarkersByState: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred while filtering accounts by state');
        }
    }
    
    /**
     * @description Retrieves account markers filtered by postal code
     * @param zipCode The postal code to filter by
     * @param limitSize Maximum number of accounts to return
     * @return List of AccountMapMarker objects with the specified postal code
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountMapMarker> getMarkersByZipCode(String zipCode, Integer limitSize) {
        String sanitizedZipCode = sanitizeInput(zipCode);
        
        try {
            return service.getAccountMarkersByPostalCode(sanitizedZipCode, limitSize);
        } catch (AccountGeoService.InvalidGeolocationException e) {
            throw new AuraHandledException('No accounts found: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getMarkersByZipCode: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred while filtering accounts by zip code');
        }
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
        
        return String.escapeSingleQuotes(input.trim()).escapeHtml4();
    }
}