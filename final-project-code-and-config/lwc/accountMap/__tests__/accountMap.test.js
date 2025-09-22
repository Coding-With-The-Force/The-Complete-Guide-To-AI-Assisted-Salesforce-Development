import { createElement } from 'lwc';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';
import AccountMap from 'c/accountMap';
import getInitialMarkers from '@salesforce/apex/AccountMapController.getInitialMarkers';
import getMarkersNearAccountName from '@salesforce/apex/AccountMapController.getMarkersNearAccountName';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/AccountMapController.getInitialMarkers',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/AccountMapController.getMarkersNearAccountName',
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

// Mock Custom Labels
jest.mock('@salesforce/label/c.AccountMap_Title', () => ({ default: 'Account Location Map' }), { virtual: true });
jest.mock('@salesforce/label/c.AccountMap_SearchLabel', () => ({ default: 'Search for Account' }), { virtual: true });
jest.mock('@salesforce/label/c.AccountMap_SearchPlaceholder', () => ({ default: 'Enter account name and press Enter' }), { virtual: true });
jest.mock('@salesforce/label/c.AccountMap_ErrorTitle', () => ({ default: 'Error' }), { virtual: true });
jest.mock('@salesforce/label/c.AccountMap_NoAccountsFound', () => ({ default: 'No accounts found with the specified criteria.' }), { virtual: true });
jest.mock('@salesforce/label/c.AccountMap_LoadingMessage', () => ({ default: 'Loading account locations...' }), { virtual: true });

// Mock data
const MOCK_MARKERS = [
    {
        accountId: '001000000000001',
        name: 'Test Account 1',
        latitude: 37.7749,
        longitude: -122.4194,
        description: 'Account: Test Account 1\nAnnual Revenue: $1000000\nPhone: 415-555-0100\nAddress: 1 Market Street, San Francisco, CA, 94105, USA',
        icon: 'custom:custom26'
    },
    {
        accountId: '001000000000002', 
        name: 'Test Account 2',
        latitude: 37.8044,
        longitude: -122.2712,
        description: 'Account: Test Account 2\nAnnual Revenue: $500000\nPhone: 510-555-0200\nAddress: 1000 Broadway, Oakland, CA, 94607, USA',
        icon: 'custom:custom26'
    }
];

describe('c-account-map', () => {
    afterEach(() => {
        // Clear all mocks and reset DOM
        jest.clearAllMocks();
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    // Helper function to create component
    function createComponent(props = {}) {
        const element = createElement('c-account-map', {
            is: AccountMap
        });
        
        // Set any provided properties
        Object.assign(element, props);
        
        document.body.appendChild(element);
        return element;
    }

    // Helper function to wait for promises
    function flushPromises() {
        return new Promise(resolve => setImmediate(resolve));
    }

    describe('Component Initialization', () => {
        it('should render with default properties', () => {
            const element = createComponent();

            // Verify card title
            const lightningCard = element.shadowRoot.querySelector('lightning-card');
            expect(lightningCard.title).toBe('Account Location Map');
            expect(lightningCard.iconName).toBe('standard:location');

            // Verify search input
            const searchInput = element.shadowRoot.querySelector('lightning-input');
            expect(searchInput.label).toBe('Search for Account');
            expect(searchInput.placeholder).toBe('Enter account name and press Enter');
        });

        it('should set api properties correctly', () => {
            const element = createComponent({
                radiusMiles: 25,
                initialLimit: 100
            });

            expect(element.radiusMiles).toBe(25);
            expect(element.initialLimit).toBe(100);
        });
    });

    describe('Wire Adapter - Initial Markers', () => {
        it('should display markers when wire returns data', async () => {
            const element = createComponent();

            // Emit data from wire adapter
            getInitialMarkers.emit(MOCK_MARKERS);

            await flushPromises();

            // Verify map markers are set
            expect(element.mapMarkers).toHaveLength(2);
            expect(element.hasMapMarkers).toBe(true);

            // Verify lightning-map is rendered
            const lightningMap = element.shadowRoot.querySelector('lightning-map');
            expect(lightningMap).toBeTruthy();
            expect(lightningMap.mapMarkers).toHaveLength(2);
        });

        it('should handle wire error', async () => {
            const element = createComponent();
            const mockError = { 
                body: { message: 'Test error message' }, 
                ok: false, 
                status: 400, 
                statusText: 'Bad Request' 
            };

            // Emit error from wire adapter
            getInitialMarkers.error(mockError);

            await flushPromises();

            // Verify error handling
            expect(element.mapMarkers).toHaveLength(0);
            expect(element.hasMapMarkers).toBe(false);
            
            // Verify no accounts message is shown
            const noAccountsDiv = element.shadowRoot.querySelector('div[class*="slds-text-align_center"]');
            expect(noAccountsDiv).toBeTruthy();
        });
    });

    describe('Search Functionality', () => {
        it('should update search term on input change', async () => {
            const element = createComponent();
            const searchInput = element.shadowRoot.querySelector('lightning-input');

            // Simulate input change
            searchInput.value = 'Test Search';
            searchInput.dispatchEvent(new CustomEvent('change', {
                detail: { value: 'Test Search' }
            }));

            await flushPromises();

            expect(element.searchTerm).toBe('Test Search');
        });

        it('should trigger search on Enter key press', async () => {
            getMarkersNearAccountName.mockResolvedValue(MOCK_MARKERS);
            
            const element = createComponent({ radiusMiles: 50 });
            const searchInput = element.shadowRoot.querySelector('lightning-input');

            // Set search term first
            element.searchTerm = 'Test Account';
            
            // Simulate Enter key press
            const enterKeyEvent = new KeyboardEvent('keydown', {
                keyCode: 13,
                bubbles: true
            });
            searchInput.dispatchEvent(enterKeyEvent);

            await flushPromises();

            // Verify apex method was called
            expect(getMarkersNearAccountName).toHaveBeenCalledWith({
                accountName: 'Test Account',
                radiusMiles: 50
            });
        });

        it('should show warning for empty search term', async () => {
            const element = createComponent();
            const searchInput = element.shadowRoot.querySelector('lightning-input');
            
            // Mock toast handler
            const toastHandler = jest.fn();
            element.addEventListener(ShowToastEventName, toastHandler);

            // Simulate Enter key with empty search
            element.searchTerm = '';
            const enterKeyEvent = new KeyboardEvent('keydown', {
                keyCode: 13,
                bubbles: true
            });
            searchInput.dispatchEvent(enterKeyEvent);

            await flushPromises();

            // Verify toast was dispatched
            expect(toastHandler).toHaveBeenCalled();
            const toastEvent = toastHandler.mock.calls[0][0];
            expect(toastEvent.detail.title).toBe('Warning');
            expect(toastEvent.detail.message).toBe('Please enter an account name to search');
        });

        it('should handle successful search results', async () => {
            getMarkersNearAccountName.mockResolvedValue(MOCK_MARKERS);
            
            const element = createComponent({ radiusMiles: 50 });
            
            // Mock toast handler
            const toastHandler = jest.fn();
            element.addEventListener(ShowToastEventName, toastHandler);

            // Set search term and trigger search
            element.searchTerm = 'Test Account';
            await element.searchNearbyAccounts();

            // Verify results
            expect(element.mapMarkers).toHaveLength(2);
            expect(element.isLoading).toBe(false);
            
            // Verify success toast
            expect(toastHandler).toHaveBeenCalled();
            const toastEvent = toastHandler.mock.calls[0][0];
            expect(toastEvent.detail.title).toBe('Success');
            expect(toastEvent.detail.variant).toBe('success');
        });

        it('should handle search error', async () => {
            getMarkersNearAccountName.mockRejectedValue(
                new Error('Account not found: No account found with name containing: Invalid')
            );
            
            const element = createComponent();
            
            // Mock toast handler
            const toastHandler = jest.fn();
            element.addEventListener(ShowToastEventName, toastHandler);

            // Set search term and trigger search
            element.searchTerm = 'Invalid Account';
            await element.searchNearbyAccounts();

            // Verify error handling
            expect(element.mapMarkers).toHaveLength(0);
            expect(element.isLoading).toBe(false);
            
            // Verify error toast
            expect(toastHandler).toHaveBeenCalled();
            const toastEvent = toastHandler.mock.calls[0][0];
            expect(toastEvent.detail.title).toBe('Error');
            expect(toastEvent.detail.variant).toBe('error');
        });

        it('should show loading spinner during search', async () => {
            // Create a promise that we can resolve manually
            let resolvePromise;
            const searchPromise = new Promise(resolve => {
                resolvePromise = resolve;
            });
            getMarkersNearAccountName.mockReturnValue(searchPromise);
            
            const element = createComponent();
            element.searchTerm = 'Test Account';
            
            // Start search
            const searchStart = element.searchNearbyAccounts();
            
            await flushPromises();
            
            // Verify loading state
            expect(element.isLoading).toBe(true);
            const spinner = element.shadowRoot.querySelector('lightning-spinner');
            expect(spinner).toBeTruthy();
            
            // Resolve the search
            resolvePromise(MOCK_MARKERS);
            await searchStart;
            
            // Verify loading state is cleared
            expect(element.isLoading).toBe(false);
        });
    });

    describe('Marker Transformation', () => {
        it('should transform markers correctly for lightning-map', () => {
            const element = createComponent();
            
            const transformedMarkers = element.transformMarkersForMap(MOCK_MARKERS);
            
            expect(transformedMarkers).toHaveLength(2);
            
            const marker = transformedMarkers[0];
            expect(marker.location.Latitude).toBe(37.7749);
            expect(marker.location.Longitude).toBe(-122.4194);
            expect(marker.title).toBe('Test Account 1');
            expect(marker.description).toBe(MOCK_MARKERS[0].description);
            expect(marker.value).toBe('001000000000001');
        });

        it('should handle null or undefined markers', () => {
            const element = createComponent();
            
            expect(element.transformMarkersForMap(null)).toEqual([]);
            expect(element.transformMarkersForMap(undefined)).toEqual([]);
            expect(element.transformMarkersForMap([])).toEqual([]);
        });
    });

    describe('Error Handling', () => {
        it('should extract error message from different error formats', () => {
            const element = createComponent();
            
            // Test with body.message
            element.handleError('Test message', { body: { message: 'Body message' } });
            expect(element.errorMessage).toBe('Body message');
            
            // Clear error
            element.clearError();
            
            // Test with body.pageErrors
            element.handleError('Test message', { 
                body: { pageErrors: [{ message: 'Page error message' }] } 
            });
            expect(element.errorMessage).toBe('Page error message');
            
            // Clear error
            element.clearError();
            
            // Test with direct message
            element.handleError('Test message', { message: 'Direct message' });
            expect(element.errorMessage).toBe('Direct message');
        });

        it('should clear error messages', () => {
            const element = createComponent();
            element.errorMessage = 'Test error';
            
            element.clearError();
            
            expect(element.errorMessage).toBe('');
        });
    });

    describe('Computed Properties', () => {
        it('should compute hasMapMarkers correctly', () => {
            const element = createComponent();
            
            // No markers
            element.mapMarkers = [];
            expect(element.hasMapMarkers).toBe(false);
            
            // With markers
            element.mapMarkers = MOCK_MARKERS;
            expect(element.hasMapMarkers).toBe(true);
        });
    });

    describe('Lifecycle Methods', () => {
        it('should initialize correctly on connectedCallback', () => {
            const element = createComponent();
            
            // Verify initial state
            expect(element.errorMessage).toBe('');
            expect(element.searchTerm).toBe('');
            expect(element.isLoading).toBe(false);
        });
    });
});
