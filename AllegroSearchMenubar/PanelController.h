#import "BackgroundView.h"
#import "StatusItemView.h"

@class PanelController;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource>
{
    BOOL _hasActivePanel;
    BOOL _isLoadingAnimationActive;
    BOOL _isListAnimationActive;
    
    __unsafe_unretained BackgroundView *_backgroundView;
    __unsafe_unretained id<PanelControllerDelegate> _delegate;
    __unsafe_unretained NSSearchField *_searchField;
    __unsafe_unretained NSTextField *_textField;
    __unsafe_unretained NSProgressIndicator *_searchLoader;
    __unsafe_unretained NSTableView *_productGrid;
    NSMutableArray *_products;
}

@property (strong) NSMutableArray *products;

@property (nonatomic, unsafe_unretained) IBOutlet NSTableView *productGrid;
@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, unsafe_unretained) IBOutlet NSSearchField *searchField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *textField;
@property (nonatomic, unsafe_unretained) IBOutlet NSProgressIndicator *searchLoader;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;

- (void)setLoadingAnimation:(BOOL)active;
- (void)setListAnimation:(BOOL)active;

@end
