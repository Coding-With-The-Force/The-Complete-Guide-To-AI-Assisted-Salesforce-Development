/**
 * @description Controller class for Account Map Lightning Web Component
 * Provides AuraEnabled methods for retrieving account geolocation data
 * Follows security best practices with no business logic in controller methods
 * 
 * @author System Administrator
 * @since 2025-01-21
 */
public with sharing class AccountMapController {
    
    /**
     * @description Retrieves initial set of account markers for map display
     * @param limitSize Maximum number of accounts to return
     * @return List of AccountMapMarker objects for map display
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountMapMarker> getInitialMarkers(Integer limitSize) {
        try {
            return AccountGeoService.getInitialAccountMarkers(limitSize);
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
        try {
            return AccountGeoService.getAccountMarkersNearAccountName(accountName, radiusMiles);
        } catch (AccountGeoService.NoCenterAccountFoundException e) {
            throw new AuraHandledException('Account not found: ' + e.getMessage());
        } catch (AccountGeoService.InvalidGeolocationException e) {
            throw new AuraHandledException('Invalid location data: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getMarkersNearAccountName: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred while searching for nearby accounts');
        }
    }
}
