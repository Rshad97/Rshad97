#import "ASXCellGuard.h"
#import <objc/runtime.h>

@interface ASXCellState : NSObject
@property (nonatomic) BOOL requestedHidden;
@end
@implementation ASXCellState
@end

static char ASXStateKey;
static NSHashTable<UITableViewCell *> *ASXManagedCells;
static BOOL (*ASXEnabledProvider)(void);
static void (*ASXOriginalHidden)(id, SEL, BOOL);
static void (*ASXOriginalReuse)(id, SEL);
static void (*ASXOriginalLayout)(id, SEL);

static BOOL ASXProtected(void) { return ASXEnabledProvider && ASXEnabledProvider(); }
static ASXCellState *ASXState(UITableViewCell *cell) {
    return objc_getAssociatedObject(cell, &ASXStateKey);
}
static void ASXApply(UITableViewCell *cell, ASXCellState *state) {
    // Bypass our setter so forced hiding never overwrites the app's requested state.
    ASXOriginalHidden(cell, @selector(setHidden:), ASXProtected() ? YES : state.requestedHidden);
}
static void ASXSetHidden(UITableViewCell *cell, SEL selector, BOOL requested) {
    ASXCellState *state = ASXState(cell);
    if (state) {
        state.requestedHidden = requested;
        if (ASXProtected()) requested = YES;
    }
    ASXOriginalHidden(cell, selector, requested);
}
static void ASXUnbind(UITableViewCell *cell) {
    ASXCellState *state = ASXState(cell);
    if (!state) return;
    objc_setAssociatedObject(cell, &ASXStateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [ASXManagedCells removeObject:cell];
    ASXOriginalHidden(cell, @selector(setHidden:), state.requestedHidden);
}
static void ASXPrepareForReuse(UITableViewCell *cell, SEL selector) {
    // Clear the old item before UIKit or X configures the next item.
    ASXUnbind(cell);
    ASXOriginalReuse(cell, selector);
}
static void ASXLayout(UITableViewCell *cell, SEL selector) {
    ASXOriginalLayout(cell, selector);
    ASXCellState *state = ASXState(cell);
    if (state) ASXApply(cell, state);
}
static IMP ASXReplace(SEL selector, IMP replacement) {
    Class cls = UITableViewCell.class;
    Method method = class_getInstanceMethod(cls, selector);
    IMP original = method_getImplementation(method);
    const char *types = method_getTypeEncoding(method);
    // Add an override for inherited UIView methods; never replace UIView globally.
    if (!class_addMethod(cls, selector, replacement, types)) {
        class_replaceMethod(cls, selector, replacement, types);
    }
    return original;
}
void ASXInstallCellGuards(BOOL (*enabled)(void)) {
    NSCAssert(NSThread.isMainThread, @"X cell guards require the main thread");
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ASXEnabledProvider = enabled;
        ASXManagedCells = [NSHashTable weakObjectsHashTable];
        ASXOriginalHidden = (void (*)(id, SEL, BOOL))ASXReplace(@selector(setHidden:), (IMP)ASXSetHidden);
        ASXOriginalReuse = (void (*)(id, SEL))ASXReplace(@selector(prepareForReuse), (IMP)ASXPrepareForReuse);
        ASXOriginalLayout = (void (*)(id, SEL))ASXReplace(@selector(layoutSubviews), (IMP)ASXLayout);
    });
}
void ASXBindCell(UITableViewCell *cell, BOOL promoted) {
    if (!ASXOriginalHidden || ![cell isKindOfClass:UITableViewCell.class]) return;
    if (!promoted) { ASXUnbind(cell); return; }
    ASXCellState *state = ASXState(cell);
    if (!state) {
        state = [ASXCellState new];
        state.requestedHidden = cell.hidden;
        objc_setAssociatedObject(cell, &ASXStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [ASXManagedCells addObject:cell];
    }
    ASXApply(cell, state);
}
void ASXRefreshCells(void) {
    for (UITableViewCell *cell in ASXManagedCells.allObjects) {
        ASXCellState *state = ASXState(cell);
        if (state) ASXApply(cell, state);
    }
}
