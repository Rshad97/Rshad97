#import "ASXSupport.h"
#include <string.h>

BOOL ASXMethodMatches(Class cls, SEL selector, const char *returnType, NSUInteger argumentCount) {
    NSMethodSignature *sig = [cls instanceMethodSignatureForSelector:selector];
    if (!sig || sig.numberOfArguments != argumentCount || strcmp(sig.methodReturnType, returnType)) return NO;
    for (NSUInteger i = 2; i < argumentCount; i++) {
        if ([sig getArgumentTypeAtIndex:i][0] != '@') return NO;
    }
    return YES;
}

BOOL ASXIsPromoted(id item) {
    // No KVC guesses, object casts of BOOL results, or text-based ad detection.
    SEL selector = NSSelectorFromString(@"isPromoted");
    if (![item respondsToSelector:selector]) return NO;
    NSMethodSignature *sig = [item methodSignatureForSelector:selector];
    if (sig.numberOfArguments != 2 || sig.methodReturnLength != 1 ||
        (strcmp(sig.methodReturnType, "B") && strcmp(sig.methodReturnType, "c"))) return NO;
    @try {
        NSInvocation *call = [NSInvocation invocationWithMethodSignature:sig];
        call.target = item;
        call.selector = selector;
        [call invoke];
        unsigned char promoted = 0;
        [call getReturnValue:&promoted];
        return promoted != 0;
    } @catch (__unused NSException *exception) { return NO; }
}
