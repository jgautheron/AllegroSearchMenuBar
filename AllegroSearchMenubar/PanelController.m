#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"

#import "AllegroApi.h"
#import "Product.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 60
#define PANEL_WIDTH 280
#define MENU_ANIMATION_DURATION .1

#define MENU_TYPING_ANIMATION_POPUP_HEIGHT 95

#pragma mark -

static NSString *const eventProductsLoaded = @"productsLoaded";

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize searchField = _searchField;
@synthesize textField = _textField;
@synthesize searchLoader = _searchLoader;
@synthesize productGrid = _productGrid;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // configure Grid
    [_productGrid setDataSource:self];
    [_productGrid setDelegate:self];
    
    // Follow search string
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runSearch) name:NSControlTextDidChangeNotification object:self.searchField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notify:) name:eventProductsLoaded object: [AllegroApi sharedManager]];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
    
    NSRect searchRect = [self.searchField frame];
    searchRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    searchRect.origin.x = SEARCH_INSET;
    searchRect.origin.y = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET - NSHeight(searchRect);
    
    if (NSIsEmptyRect(searchRect))
    {
        [self.searchField setHidden:YES];
    }
    else
    {
        [self.searchField setFrame:searchRect];
        [self.searchField setHidden:NO];
    }
    
    NSRect textRect = [self.textField frame];
    textRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    textRect.origin.x = SEARCH_INSET + 20; // loader width + padding
    textRect.size.height = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET * 3 - NSHeight(searchRect);
    textRect.origin.y = SEARCH_INSET;
    
    if (NSIsEmptyRect(textRect))
    {
        [self.textField setHidden:YES];
    }
    else
    {
        [self.textField setFrame:textRect];
        [self.textField setHidden:NO];
    }
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

- (void)runSearch
{
    NSString *searchFormat = @"";
    NSString *searchString = [self.searchField stringValue];
    
    NSLog(@"%lu", [searchString length]);
    
    if ([searchString length] >= 3) {
        
        searchFormat = NSLocalizedString(@"Searching for ‘%@’…", @"Format for search request");
        [_searchLoader startAnimation:self];
        [self setLoadingAnimation:YES];
        
        NSString *searchRequest = [NSString stringWithFormat:searchFormat, searchString];
        [self.textField setStringValue:searchRequest];
        
        // search Allegro
        AllegroApi *sharedManager = [AllegroApi sharedManager];
        [sharedManager search:searchString];
    }
    else
    {
        [_searchLoader stopAnimation:self];
        [self setLoadingAnimation:NO];
    }
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.size.height = POPUP_HEIGHT;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT)) {
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    }
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed) {
            openDuration *= 10;
            
            if (shiftOptionPressed) {
                NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
                      NSStringFromRect(statusRect), NSStringFromRect(screenRect), NSStringFromRect(panelRect));
            }
        }
    }
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
    [panel performSelector:@selector(makeFirstResponder:) withObject:self.searchField afterDelay:openDuration];
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        [self.window orderOut:nil];
    });
}

- (void)setLoadingAnimation:(BOOL)active
{
    NSInteger frameHeight  = MENU_TYPING_ANIMATION_POPUP_HEIGHT;
    NSInteger frameOriginY = MENU_TYPING_ANIMATION_POPUP_HEIGHT - POPUP_HEIGHT;
    
    NSWindow *panel = [self window];
    NSRect    frame = [panel frame];
    
    if (_isLoadingAnimationActive == YES) {
        // do not repeat twice the animation if already applied
        if (active) {
            return;
        }
        
        // revert back to the original height
        frame.size.height = POPUP_HEIGHT;
        frame.origin.y += frameOriginY;
        [panel setFrame:frame display:YES animate:YES];
        
        _isLoadingAnimationActive = NO;
        _isListAnimationActive    = NO;
        
        return;
    }
    
    if (!active) {
        return;
    }
    
    frame.size.height = frameHeight;
    frame.origin.y -= frameOriginY;
    [panel setFrame:frame display:YES animate:YES];
    
    _isLoadingAnimationActive = YES;
}

- (void)setListAnimation:(BOOL)active
{
    if (_isLoadingAnimationActive == NO) {
        return;
    }
    
    NSInteger frameHeight  = 300;
    NSInteger frameOriginY = 300 - MENU_TYPING_ANIMATION_POPUP_HEIGHT;
    
    NSWindow *panel = [self window];
    NSRect    frame = [panel frame];
    
    if (_isListAnimationActive == YES) {
        // do not repeat twice the animation if already applied
        if (active) {
            return;
        }
        
        // revert back to the original height
        frame.size.height = MENU_TYPING_ANIMATION_POPUP_HEIGHT;
        frame.origin.y += frameOriginY;
        [panel setFrame:frame display:YES animate:YES];
        
        _isListAnimationActive = NO;
        
        return;
    }
    
    if (!active) {
        return;
    }
    
    frame.size.height  = frameHeight;
    frame.origin.y    -= frameOriginY;
    [panel setFrame:frame display:YES animate:YES];
    
    _isListAnimationActive = YES;
    
}

- (void)notify:(NSNotification *)notification {
	id notificationSender = [notification object];
    
    NSMutableArray *products = [notificationSender getProducts];
    
    NSLog(@"%@", [[products objectAtIndex:1] objectForKey:@"ns1:sItName"]);
    [self setListAnimation:YES];
    self.products = products;
    
    [_productGrid reloadData];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSLog(tableColumn.identifier);
    
    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    // Since this is a single-column table view, this would not be necessary.
    // But it's a good practice to do it in order by remember it when a table is multicolumn.
    if ([tableColumn.identifier isEqualToString:@"ProductColumn"])
    {
        Product *product = [self.products objectAtIndex:row];
        cellView.imageView.image = product.thumbImage;
        cellView.textField.stringValue = product.title;
        return cellView;
    }
    return cellView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.products count];
}

@end
