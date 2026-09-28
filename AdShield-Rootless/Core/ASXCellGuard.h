#import <UIKit/UIKit.h>

// Only install in X after its controller ABI has been validated. All calls on main.
FOUNDATION_EXPORT void ASXInstallCellGuards(BOOL (*enabled)(void));
FOUNDATION_EXPORT void ASXBindCell(UITableViewCell *cell, BOOL promoted);
FOUNDATION_EXPORT void ASXRefreshCells(void);
