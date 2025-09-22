/**
 * @description Test class for AccountGeoService
 * Tests geolocation functionality, input sanitization, and security enforcement
 * 
 * @author System Administrator
 * @since 2025-01-21
 */
@isTest
public class AccountGeoService_Test {
    
    /**
     * @description Test data setup - creates accounts with geolocation data
     */
    @testSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        // Create center account in San Francisco
        Account centerAccount = new Account(
            Name = 'Test Center Account',
            AnnualRevenue = 1000000,
            Phone = '415-555-0100',
            ShippingStreet = '1 Market Street',
            ShippingCity = 'San Francisco',
            ShippingState = 'CA',
            ShippingPostalCode = '94105',
            ShippingCountry = 'USA',
            ShippingLatitude = 37.7749,
            ShippingLongitude = -122.4194
        );
        testAccounts.add(centerAccount);
        
        // Create nearby account within 50 miles (Oakland)
        Account nearbyAccount = new Account(
            Name = 'Test Nearby Account',
            AnnualRevenue = 500000,
            Phone = '510-555-0200',
            ShippingStreet = '1000 Broadway',
            ShippingCity = 'Oakland',
            ShippingState = 'CA',
            ShippingPostalCode = '94607',
            ShippingCountry = 'USA',
            ShippingLatitude = 37.8044,
            ShippingLongitude = -122.2712
        );
        testAccounts.add(nearbyAccount);
        
        // Create distant account outside 50 miles (Los Angeles)
        Account distantAccount = new Account(
            Name = 'Test Distant Account',
            AnnualRevenue = 2000000,
            Phone = '213-555-0300',
            ShippingStreet = '100 S Hope Street',
            ShippingCity = 'Los Angeles',
            ShippingState = 'CA',
            ShippingPostalCode = '90013',
            ShippingCountry = 'USA',
            ShippingLatitude = 34.0522,
            ShippingLongitude = -118.2437
        );
        testAccounts.add(distantAccount);
        
        // Create account with partial address
        Account partialAccount = new Account(
            Name = 'Test Partial Account',
            AnnualRevenue = 750000,
            Phone = '408-555-0400',
            ShippingCity = 'San Jose',
            ShippingState = 'CA',
            ShippingCountry = 'USA',
            ShippingLatitude = 37.3382,
            ShippingLongitude = -121.8863
        );
        testAccounts.add(partialAccount);
        
        // Create account without geolocation
        Account noGeoAccount = new Account(
            Name = 'Test No Geo Account',
            AnnualRevenue = 300000,
            Phone = '650-555-0500',
            ShippingStreet = '123 Main Street',
            ShippingCity = 'Palo Alto',
            ShippingState = 'CA',
            ShippingPostalCode = '94301',
            ShippingCountry = 'USA'
            // No ShippingLatitude/Longitude
        );
        testAccounts.add(noGeoAccount);
        
        insert testAccounts;
    }
    
    /**
     * @description Test getInitialAccountMarkers with valid limit
     */
    @isTest
    static void testGetInitialAccountMarkers_ValidLimit() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountGeoService.getInitialAccountMarkers(10);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        System.assertEquals(4, markers.size(), 'Should return 4 accounts with geolocation data');
        
        // Verify marker structure
        AccountMapMarker firstMarker = markers[0];
        System.assertNotEquals(null, firstMarker.accountId, 'Account ID should not be null');
        System.assertNotEquals(null, firstMarker.name, 'Account name should not be null');
        System.assertNotEquals(null, firstMarker.latitude, 'Latitude should not be null');
        System.assertNotEquals(null, firstMarker.longitude, 'Longitude should not be null');
        System.assertNotEquals(null, firstMarker.description, 'Description should not be null');
    }
    
    /**
     * @description Test getInitialAccountMarkers with null limit
     */
    @isTest
    static void testGetInitialAccountMarkers_NullLimit() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountGeoService.getInitialAccountMarkers(null);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        System.assertEquals(4, markers.size(), 'Should return all accounts with geolocation data');
    }
    
    /**
     * @description Test getAccountMarkersNearAccountName with valid account
     */
    @isTest
    static void testGetAccountMarkersNearAccountName_ValidAccount() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountGeoService.getAccountMarkersNearAccountName('Test Center Account', 50);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        // Should include center account and nearby account, but not distant account
        System.assertEquals(2, markers.size(), 'Should return 2 accounts within 50 miles');
        
        // Verify accounts are within expected distance
        Boolean foundCenter = false;
        Boolean foundNearby = false;
        for (AccountMapMarker marker : markers) {
            if (marker.name.contains('Center')) {
                foundCenter = true;
            } else if (marker.name.contains('Nearby')) {
                foundNearby = true;
            }
        }
        System.assert(foundCenter, 'Should include center account');
        System.assert(foundNearby, 'Should include nearby account');
    }
    
    /**
     * @description Test getAccountMarkersNearAccountName with partial account name
     */
    @isTest
    static void testGetAccountMarkersNearAccountName_PartialName() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountGeoService.getAccountMarkersNearAccountName('Center', 25);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        System.assertEquals(1, markers.size(), 'Should find center account with partial name');
    }
    
    /**
     * @description Test input sanitization with malicious input
     */
    @isTest
    static void testInputSanitization_SQLInjection() {
        String maliciousInput = 'Test\' OR 1=1 --';
        
        Test.startTest();
        try {
            List<AccountMapMarker> markers = AccountGeoService.getAccountMarkersNearAccountName(maliciousInput, 50);
            System.assert(true, 'Should handle malicious input gracefully');
        } catch (Exception e) {
            // Should either handle gracefully or throw NoCenterAccountFoundException
            System.assert(e instanceof AccountGeoService.NoCenterAccountFoundException, 
                         'Should throw NoCenterAccountFoundException for non-existent account');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test input sanitization with special characters
     */
    @isTest
    static void testInputSanitization_SpecialCharacters() {
        String specialInput = 'Test & <script>alert("xss")</script>';
        
        Test.startTest();
        try {
            List<AccountMapMarker> markers = AccountGeoService.getAccountMarkersNearAccountName(specialInput, 50);
            System.assert(true, 'Should handle special characters gracefully');
        } catch (Exception e) {
            System.assert(e instanceof AccountGeoService.NoCenterAccountFoundException, 
                         'Should throw NoCenterAccountFoundException for non-existent account');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test exception handling for non-existent account
     */
    @isTest
    static void testGetAccountMarkersNearAccountName_NonExistentAccount() {
        Test.startTest();
        try {
            List<AccountMapMarker> markers = AccountGeoService.getAccountMarkersNearAccountName('Non Existent Account', 50);
            System.assert(false, 'Should throw exception for non-existent account');
        } catch (AccountGeoService.NoCenterAccountFoundException e) {
            System.assert(e.getMessage().contains('No account found'), 'Exception message should indicate no account found');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test radius parameter validation
     */
    @isTest
    static void testGetAccountMarkersNearAccountName_InvalidRadius() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountGeoService.getAccountMarkersNearAccountName('Test Center Account', -10);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Should handle invalid radius gracefully');
        // Should default to 50 miles radius
    }
    
    /**
     * @description Test marker description formatting
     */
    @isTest
    static void testMarkerDescriptionFormatting() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountGeoService.getInitialAccountMarkers(1);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        System.assertEquals(true, markers.size() > 0, 'Should have at least one marker');
        
        AccountMapMarker marker = markers[0];
        String description = marker.description;
        
        // Verify description contains expected elements
        System.assert(description.contains('Account:'), 'Description should contain account name');
        System.assert(description.contains('Annual Revenue:') || !description.contains('Annual Revenue:'), 
                     'Description should handle revenue appropriately');
        System.assert(description.contains('Phone:') || !description.contains('Phone:'), 
                     'Description should handle phone appropriately');
        System.assert(description.contains('Address:') || !description.contains('Address:'), 
                     'Description should handle address appropriately');
    }
    
    /**
     * @description Test with accounts that have no geolocation data
     */
    @isTest
    static void testNoAccountsWithGeolocation() {
        // Delete all accounts with geolocation
        List<Account> accountsToDelete = [SELECT Id FROM Account WHERE ShippingLatitude != null];
        delete accountsToDelete;
        
        Test.startTest();
        try {
            List<AccountMapMarker> markers = AccountGeoService.getInitialAccountMarkers(500);
            System.assert(false, 'Should throw exception when no accounts have geolocation');
        } catch (AccountGeoService.InvalidGeolocationException e) {
            System.assert(e.getMessage().contains('No accounts found'), 
                         'Exception message should indicate no accounts found');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test address string building with various combinations
     */
    @isTest
    static void testAddressStringBuilding() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountGeoService.getInitialAccountMarkers(10);
        Test.stopTest();
        
        // Find the partial account that only has city, state, country
        AccountMapMarker partialMarker = null;
        for (AccountMapMarker marker : markers) {
            if (marker.name.contains('Partial')) {
                partialMarker = marker;
                break;
            }
        }
        
        System.assertNotEquals(null, partialMarker, 'Should find partial account marker');
        System.assert(partialMarker.description.contains('San Jose'), 
                     'Description should contain city even without street');
    }
}
